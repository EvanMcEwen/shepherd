defmodule ShepherdWeb.DeviceChannel do
  @moduledoc """
  Channel for device communication.

  Handles:
  - Device joining and presence tracking
  - Status updates from devices (firmware info)
  - Command dispatch to devices
  - Cleanup on disconnect (mark offline, record last_seen_at)
  """

  use Phoenix.Channel

  require Logger

  alias Shepherd.Devices
  alias Shepherd.Presence

  @impl true
  def join("device:" <> serial, _payload, socket) do
    device = socket.assigns.device

    if device.serial == serial do
      send(self(), :after_join)
      {:ok, %{server_time: DateTime.utc_now()}, socket}
    else
      Logger.warning("[DeviceChannel] Serial mismatch: socket=#{device.serial}, requested=#{serial}")
      {:error, %{reason: "serial_mismatch"}}
    end
  end

  @impl true
  def handle_info(:after_join, socket) do
    device = socket.assigns.device

    # Track in Presence
    {:ok, _} =
      Presence.track(self(), Presence.topic(), device.serial, %{
        device_id: device.id,
        joined_at: DateTime.utc_now(),
        firmware_version: device.firmware_version,
        firmware_target: device.firmware_target
      })

    # Mark online in database
    {:ok, device} = Devices.update_status(device, :online)

    # Subscribe to commands for this device
    Phoenix.PubSub.subscribe(Shepherd.PubSub, "device_commands:#{device.id}")

    # Broadcast device online event
    Phoenix.PubSub.broadcast(Shepherd.PubSub, "devices", {:device_online, device})

    {:noreply, assign(socket, :device, device)}
  end

  @impl true
  def handle_info(:revoke, socket) do
    device = socket.assigns.device
    Logger.warning("[DeviceChannel] Device #{device.serial} revoked — terminating channel")
    push(socket, "revoked", %{})
    {:stop, {:shutdown, :revoked}, socket}
  end

  @impl true
  def handle_info({:command, command, payload}, socket) do
    push(socket, "command", %{command: command, payload: payload})
    {:noreply, socket}
  end

  @impl true
  def handle_in("status", payload, socket) do
    device = socket.assigns.device

    attrs = %{
      firmware_version: payload["firmware_version"],
      firmware_target: payload["firmware_target"],
      metadata: Map.merge(device.metadata || %{}, %{
        "firmware_uuid" => payload["firmware_uuid"]
      })
    }

    case Devices.update_device_info(device, attrs) do
      {:ok, device} ->
        # Auto-update firmware record UUID if reported by device
        maybe_update_firmware_uuid(payload)

        # Update presence metadata
        Presence.update(self(), Presence.topic(), device.serial, %{
          device_id: device.id,
          joined_at: DateTime.utc_now(),
          firmware_version: device.firmware_version,
          firmware_target: device.firmware_target
        })

        {:reply, :ok, assign(socket, :device, device)}

      {:error, _changeset} ->
        {:reply, {:error, %{reason: "update_failed"}}, socket}
    end
  end

  @impl true
  def handle_in("metrics", %{"metrics" => metrics}, socket) when is_list(metrics) do
    device_id = socket.assigns.device.id

    {:ok, count} = Shepherd.Metrics.ingest(device_id, metrics)

    {:reply, {:ok, %{ingested: count}}, socket}
  end

  def handle_in("metrics", _payload, socket) do
    {:reply, {:error, %{reason: "invalid_payload"}}, socket}
  end

  @impl true
  def handle_in("update_status", payload, socket) do
    device = socket.assigns.device
    status = payload["status"]

    Logger.info("[DeviceChannel] Device #{device.serial} update status: #{status}")

    # Update firmware_update status if there's an active update
    update_firmware_update_status(device.id, status)

    # Broadcast to any listeners (future: LiveView UI)
    Phoenix.PubSub.broadcast(
      Shepherd.PubSub,
      "device:#{device.id}:updates",
      {:update_status, payload}
    )

    # Emit telemetry for observability
    :telemetry.execute(
      [:shepherd, :device, :update_status],
      %{},
      %{device_id: device.id, status: status, payload: payload}
    )

    {:reply, :ok, socket}
  end


  @impl true
  def terminate(_reason, socket) do
    device = socket.assigns.device

    # Mark offline and record last_seen_at
    {:ok, device} = Devices.update_status(device, :offline)

    # Broadcast device offline event
    Phoenix.PubSub.broadcast(Shepherd.PubSub, "devices", {:device_offline, device})

    Logger.info("[DeviceChannel] Device #{device.serial} disconnected")

    :ok
  end

  # --- Private ---

  defp update_firmware_update_status(device_id, status_string) do
    status_atom =
      case status_string do
        "pending" -> :pending
        "downloading" -> :downloading
        "applying" -> :applying
        "complete" -> :complete
        "failed" -> :failed
        _ -> nil
      end

    if status_atom do
      case Shepherd.Firmware.get_active_firmware_update(device_id) do
        %Shepherd.Firmware.FirmwareUpdate{} = fu ->
          Shepherd.Firmware.update_firmware_update_status(fu, %{status: status_atom})

        nil ->
          :ok
      end
    end
  end

  # Auto-update firmware record UUID when device reports it
  defp maybe_update_firmware_uuid(%{
         "firmware_uuid" => uuid,
         "firmware_target" => target,
         "firmware_version" => version
       })
       when not is_nil(uuid) and not is_nil(target) and not is_nil(version) do
    # Find firmware records with matching target+version that don't have a UUID yet
    case Shepherd.Firmware.find_firmware_without_uuid(target, version) do
      [] ->
        # No matching firmware found, nothing to update
        :ok

      firmwares ->
        # Update all matching firmware records with the reported UUID
        Enum.each(firmwares, fn firmware ->
          case Shepherd.Firmware.update_firmware(firmware, %{uuid: uuid}) do
            {:ok, _} ->
              Logger.info(
                "[DeviceChannel] Updated firmware #{firmware.id} (#{target}/#{firmware.application}/#{version}) with UUID: #{uuid}"
              )

            {:error, changeset} ->
              Logger.warning(
                "[DeviceChannel] Failed to update firmware #{firmware.id} UUID: #{inspect(changeset.errors)}"
              )
          end
        end)
    end
  end

  defp maybe_update_firmware_uuid(_payload), do: :ok
end
