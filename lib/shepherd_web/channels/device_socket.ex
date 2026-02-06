defmodule ShepherdWeb.DeviceSocket do
  @moduledoc """
  WebSocket entry point for device connections.

  Authenticates devices using certificate-based signatures before
  allowing channel connections. The device must provide:

  - `serial` - claimed device serial number
  - `timestamp` - unix timestamp
  - `signature` - base64-encoded signature of "serial:timestamp"
  - `cert` - base64-encoded DER certificate

  On successful authentication, the device is registered (or updated)
  in the database and assigned to the socket for channel access.
  """

  use Phoenix.Socket

  require Logger

  alias Shepherd.Auth
  alias Shepherd.Devices

  channel "device:*", ShepherdWeb.DeviceChannel

  @impl true
  def connect(params, socket, _connect_info) do
    case Auth.verify_device_auth(params) do
      {:ok, device_info} ->
        case Devices.ensure_registered(device_info) do
          {:ok, device} ->
            Logger.info("[DeviceSocket] Device #{device.serial} connected")
            {:ok, assign(socket, :device, device)}

          {:error, :revoked} ->
            Logger.warning("[DeviceSocket] Rejected revoked device: #{device_info.serial}")
            :error

          {:error, reason} ->
            Logger.error("[DeviceSocket] Registration failed: #{inspect(reason)}")
            :error
        end

      {:error, reason} ->
        Logger.warning("[DeviceSocket] Auth failed: #{inspect(reason)}")
        :error
    end
  end

  @impl true
  def id(socket), do: "device_socket:#{socket.assigns.device.id}"
end
