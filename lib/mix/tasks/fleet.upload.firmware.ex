defmodule Mix.Tasks.Fleet.Upload.Firmware do
  use Mix.Task

  @shortdoc "Upload firmware to S3 and register in database"

  @moduledoc """
  Upload firmware to S3 and register it in the database.

  ## Usage

      mix fleet.upload.firmware <path> --target <target> --application <app> --version <version> [--uuid <uuid>]

  ## Examples

      mix fleet.upload.firmware /tmp/firmware.fw --target rpi5 --application temp_monitor --version 1.2.3
      mix fleet.upload.firmware firmware.fw --target rpi4 --application client_bridge --version 1.0.0 --uuid abc123

  ## Options

    * `--target` - Target platform (required, e.g., rpi5, rpi4)
    * `--application` - Application/role name (required, e.g., temp_monitor, client_bridge)
    * `--version` - Firmware version in semver format (required)
    * `--uuid` - Optional UUID for the firmware

  """

  @requirements ["app.start"]

  alias Shepherd.Firmware
  alias Shepherd.Firmware.S3

  @impl Mix.Task
  def run(args) do
    {opts, argv, _} =
      OptionParser.parse(args,
        strict: [target: :string, application: :string, version: :string, uuid: :string],
        aliases: [t: :target, a: :application, v: :version, u: :uuid]
      )

    case argv do
      [path] ->
        upload_firmware(path, opts)

      _ ->
        Mix.shell().error(
          "Usage: mix fleet.upload.firmware <path> --target <target> --application <app> --version <version>"
        )

        exit({:shutdown, 1})
    end
  end

  defp upload_firmware(path, opts) do
    target = Keyword.get(opts, :target)
    application = Keyword.get(opts, :application)
    version = Keyword.get(opts, :version)
    uuid = Keyword.get(opts, :uuid)

    unless target && application && version do
      Mix.shell().error("--target, --application, and --version are all required")
      exit({:shutdown, 1})
    end

    unless File.exists?(path) do
      Mix.shell().error("File not found: #{path}")
      exit({:shutdown, 1})
    end

    Mix.shell().info("Computing SHA256 hash...")
    sha256 = compute_sha256(path)
    Mix.shell().info("SHA256: #{sha256}")

    # Check for duplicate
    case Firmware.get_firmware_by_sha256(sha256) do
      %Firmware.FirmwareVersion{} = existing ->
        Mix.shell().info("Firmware with this SHA256 already exists:")
        Mix.shell().info("  Target: #{existing.target}")
        Mix.shell().info("  Version: #{existing.version}")
        Mix.shell().info("  ID: #{existing.id}")
        exit({:shutdown, 0})

      nil ->
        :ok
    end

    # Check for duplicate target+application+version
    case Firmware.get_firmware_by_target_and_version(target, version) do
      %Firmware.FirmwareVersion{application: ^application} = existing ->
        Mix.shell().error(
          "Firmware already exists for target #{target} application #{application} version #{version}"
        )

        Mix.shell().error("  ID: #{existing.id}")
        Mix.shell().error("  SHA256: #{existing.sha256}")
        exit({:shutdown, 1})

      _ ->
        :ok
    end

    filename = Path.basename(path)
    s3_key = "#{application}/#{target}/#{version}/#{filename}"

    Mix.shell().info("Uploading to S3...")
    Mix.shell().info("  S3 Key: #{s3_key}")

    case S3.upload(s3_key, path) do
      {:ok, ^s3_key} ->
        Mix.shell().info("Upload successful")

      {:error, reason} ->
        Mix.shell().error("Upload failed: #{inspect(reason)}")
        exit({:shutdown, 1})
    end

    file_stat = File.stat!(path)

    attrs = %{
      version: version,
      target: target,
      application: application,
      uuid: uuid,
      s3_key: s3_key,
      sha256: sha256,
      size: file_stat.size,
      metadata: %{
        filename: filename,
        uploaded_at: DateTime.utc_now() |> DateTime.to_iso8601()
      }
    }

    Mix.shell().info("Creating database record...")

    case Firmware.create_firmware(attrs) do
      {:ok, firmware} ->
        Mix.shell().info("Firmware registered successfully")
        Mix.shell().info("  ID: #{firmware.id}")
        Mix.shell().info("  Application: #{firmware.application}")
        Mix.shell().info("  Target: #{firmware.target}")
        Mix.shell().info("  Version: #{firmware.version}")
        Mix.shell().info("  Size: #{format_size(firmware.size)}")

      {:error, changeset} ->
        Mix.shell().error("Failed to create firmware record:")
        Mix.shell().error(inspect(changeset.errors))
        exit({:shutdown, 1})
    end
  end

  defp compute_sha256(path) do
    path
    |> File.stream!([], 2048)
    |> Enum.reduce(:crypto.hash_init(:sha256), fn chunk, hash ->
      :crypto.hash_update(hash, chunk)
    end)
    |> :crypto.hash_final()
    |> Base.encode16(case: :lower)
  end

  defp format_size(bytes) when bytes < 1024, do: "#{bytes} B"
  defp format_size(bytes) when bytes < 1_048_576, do: "#{Float.round(bytes / 1024, 2)} KB"

  defp format_size(bytes) when bytes < 1_073_741_824,
    do: "#{Float.round(bytes / 1_048_576, 2)} MB"

  defp format_size(bytes), do: "#{Float.round(bytes / 1_073_741_824, 2)} GB"
end
