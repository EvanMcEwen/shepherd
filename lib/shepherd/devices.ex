defmodule Shepherd.Devices do
  @moduledoc "Context for device and group management."

  import Ecto.Query
  alias Shepherd.Repo
  alias Shepherd.Devices.Device
  alias Shepherd.Devices.Group

  # --- Registration ---

  @doc """
  Finds a device by serial or creates one. Updates cert fields on reconnection.
  Returns {:error, :revoked} if the device has been revoked.
  """
  def ensure_registered(%{serial: serial, cert_fingerprint: fingerprint, cert_not_after: not_after}) do
    case get_device_by_serial(serial) do
      %Device{revoked: true} ->
        {:error, :revoked}

      %Device{} = device ->
        device
        |> Device.registration_changeset(%{cert_fingerprint: fingerprint, cert_not_after: not_after})
        |> Repo.update()

      nil ->
        %Device{}
        |> Device.registration_changeset(%{
          serial: serial,
          cert_fingerprint: fingerprint,
          cert_not_after: not_after
        })
        |> Repo.insert()
    end
  end

  # --- Status & Heartbeat ---

  @doc "Updates device status and sets last_seen_at to now."
  def update_status(device, status) do
    device
    |> Device.status_changeset(%{status: status, last_seen_at: DateTime.utc_now()})
    |> Repo.update()
  end

  @doc "Touches last_seen_at without changing status."
  def touch(device) do
    device
    |> Ecto.Changeset.change(last_seen_at: DateTime.utc_now())
    |> Repo.update()
  end

  # --- Commands ---

  @doc "Broadcasts a command to a connected device via PubSub."
  def send_command(device, command, payload) do
    Phoenix.PubSub.broadcast(Shepherd.PubSub, "device_commands:#{device.id}", {
      :command,
      command,
      payload
    })
  end

  @doc """
  Sends a firmware update command to a device.

  Options:
    - `:reboot` - Whether to reboot after applying (default: true)

  Returns `:ok` if the device is online, `{:error, :offline}` otherwise.

  ## Example

      Devices.send_update(device, "https://example.com/firmware.fw")
      Devices.send_update(device, "https://example.com/firmware.fw", reboot: false)

  """
  def send_update(device, url, opts \\ []) do
    reboot = Keyword.get(opts, :reboot, true)

    send_command(device, "update", %{
      url: url,
      reboot: reboot
    })
  end

  @doc """
  Sends a firmware update to a device with tracking.

  This creates a firmware_update record for audit tracking and generates
  a pre-signed download URL for the firmware. The update status will be
  automatically tracked as the device progresses through the update.

  Options:
    - `:reboot` - Whether to reboot after applying (default: true)
    - `:expires_in` - URL expiration time in seconds (default: 3600)

  Returns `{:ok, firmware_update}` on success, `{:error, changeset}` on failure.

  ## Example

      firmware = Firmware.get_firmware!(1)
      Devices.send_firmware_update(device, firmware)

  """
  def send_firmware_update(device, %Shepherd.Firmware.FirmwareVersion{} = firmware, opts \\ []) do
    expires_in = Keyword.get(opts, :expires_in, 3600)

    # Generate pre-signed download URL
    {:ok, download_url} =
      Shepherd.Firmware.S3.generate_presigned_download_url(firmware.s3_key, expires_in: expires_in)

    case Shepherd.Firmware.create_firmware_update(%{
      device_id: device.id,
      firmware_id: firmware.id
    }) do
      {:ok, firmware_update} ->
        send_update(device, download_url, opts)
        {:ok, firmware_update}

      {:error, _changeset} = error ->
        error
    end
  end

  @doc """
  Subscribes to update status events for a device.

  Messages received:
    - `{:update_status, %{"status" => status, ...}}`
  """
  def subscribe_updates(device_id) do
    Phoenix.PubSub.subscribe(Shepherd.PubSub, "device:#{device_id}:updates")
  end

  # --- Queries ---

  @doc "Lists devices, optionally filtered by status and/or group_id."
  def list_devices(filters \\ %{}) do
    Device
    |> filter_by_status(filters[:status])
    |> filter_by_group(filters[:group_id])
    |> Repo.all()
  end

  @doc "Lists all currently online devices."
  def list_online_devices do
    from(d in Device, where: d.status == :online)
    |> Repo.all()
  end

  @doc "Gets a device by id. Raises if not found."
  def get_device!(id) do
    Repo.get!(Device, id)
  end

  @doc "Gets a device by serial. Returns nil if not found."
  def get_device_by_serial(serial) do
    Repo.get_by(Device, serial: serial)
  end

  @doc "Returns a map of status => count across all devices."
  def count_by_status do
    from(d in Device, group_by: d.status, select: {d.status, count()})
    |> Repo.all()
    |> Map.new(fn {status, count} -> {String.to_existing_atom(status), count} end)
  end

  # --- Management ---

  @doc "Sets a device's nickname."
  def set_nickname(device, nickname) do
    device
    |> Device.changeset(%{nickname: nickname})
    |> Repo.update()
  end

  @doc "Assigns a device to a group. Pass nil to unassign."
  def assign_to_group(device, group_id) do
    device
    |> Ecto.Changeset.change(group_id: group_id)
    |> Repo.update()
  end

  @doc """
  Revokes a device, preventing future connections.
  If the device is currently connected, its channel is terminated immediately.
  """
  def revoke_device(device) do
    device
    |> Ecto.Changeset.change(revoked: true)
    |> Repo.update()
    |> tap(fn
      {:ok, _} ->
        Phoenix.PubSub.broadcast(
          Shepherd.PubSub,
          "device_commands:#{device.id}",
          :revoke
        )

      _ -> :ok
    end)
  end

  @doc "Updates device firmware info and metadata."
  def update_device_info(device, attrs) do
    device
    |> Device.changeset(attrs)
    |> Repo.update()
  end

  # --- Groups ---

  @doc "Lists all groups."
  def list_groups do
    Repo.all(Group)
  end

  @doc "Creates a group from attrs."
  def create_group(attrs) do
    %Group{}
    |> Group.changeset(attrs)
    |> Repo.insert()
  end

  @doc "Updates a group with attrs."
  def update_group(group, attrs) do
    group
    |> Group.changeset(attrs)
    |> Repo.update()
  end

  @doc "Deletes a group. Devices in the group have group_id set to nil."
  def delete_group(group) do
    Repo.delete(group)
  end

  @doc "Gets a group by id. Raises if not found."
  def get_group!(id) do
    Repo.get!(Group, id)
  end

  @doc """
  Sets the current firmware for a group.
  This marks which firmware version the group should be running.
  """
  def set_group_firmware(group, %Shepherd.Firmware.FirmwareVersion{} = firmware) do
    group
    |> Group.changeset(%{current_firmware_id: firmware.id})
    |> Repo.update()
  end

  @doc """
  Deploys firmware to all devices in a group.
  Uses the group's current_firmware if no firmware is specified.

  Returns {:ok, count} with number of devices updated, or {:error, reason}.
  """
  def deploy_firmware_to_group(group, firmware \\ nil, opts \\ [])

  def deploy_firmware_to_group(%Group{current_firmware_id: nil}, nil, _opts) do
    {:error, :no_firmware_assigned}
  end

  def deploy_firmware_to_group(%Group{} = group, nil, opts) do
    group = Repo.preload(group, :current_firmware)
    deploy_firmware_to_group(group, group.current_firmware, opts)
  end

  def deploy_firmware_to_group(%Group{} = group, %Shepherd.Firmware.FirmwareVersion{} = firmware, opts) do
    devices = list_devices(%{group_id: group.id, status: :online})

    results =
      Enum.map(devices, fn device ->
        send_firmware_update(device, firmware, opts)
      end)

    success_count = Enum.count(results, fn {status, _} -> status == :ok end)
    {:ok, success_count}
  end

  # --- Private ---

  defp filter_by_status(query, nil), do: query
  defp filter_by_status(query, status), do: from(d in query, where: d.status == ^status)

  defp filter_by_group(query, nil), do: query
  defp filter_by_group(query, group_id), do: from(d in query, where: d.group_id == ^group_id)
end
