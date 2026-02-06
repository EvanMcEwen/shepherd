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

  # --- Private ---

  defp filter_by_status(query, nil), do: query
  defp filter_by_status(query, status), do: from(d in query, where: d.status == ^status)

  defp filter_by_group(query, nil), do: query
  defp filter_by_group(query, group_id), do: from(d in query, where: d.group_id == ^group_id)
end
