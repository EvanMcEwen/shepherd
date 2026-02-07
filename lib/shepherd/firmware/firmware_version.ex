defmodule Shepherd.Firmware.FirmwareVersion do
  use Ecto.Schema
  import Ecto.Changeset

  schema "firmwares" do
    field :version, :string
    field :target, :string
    field :application, :string
    field :uuid, :string
    field :s3_key, :string
    field :sha256, :string
    field :size, :integer
    field :metadata, :map, default: %{}

    has_many :firmware_updates, Shepherd.Firmware.FirmwareUpdate, foreign_key: :firmware_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(firmware, attrs) do
    firmware
    |> cast(attrs, [:version, :target, :application, :uuid, :s3_key, :sha256, :size, :metadata])
    |> validate_required([:version, :target, :s3_key, :sha256])
    |> validate_semver(:version)
    |> unique_constraint(:sha256)
    |> unique_constraint([:target, :application, :version])
  end

  defp validate_semver(changeset, field) do
    validate_change(changeset, field, fn _, version ->
      case Version.parse(version) do
        {:ok, _} -> []
        :error -> [{field, "must be a valid semantic version (e.g., 1.2.3)"}]
      end
    end)
  end

  @doc """
  Generate a pre-signed download URL for this firmware.
  Returns {:ok, url} or {:error, reason}.
  """
  def download_url(%__MODULE__{s3_key: s3_key}, opts \\ []) do
    Shepherd.Firmware.S3.generate_presigned_download_url(s3_key, opts)
  end
end
