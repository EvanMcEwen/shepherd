defmodule ShepherdWeb.DeviceChannelTest do
  use ShepherdWeb.ChannelCase

  alias Shepherd.Devices

  # Build valid auth params by signing with the test device's private key.
  # Mirrors the flow in ShepherdClient.Auth.build_auth_params/0.
  defp build_auth_params do
    key_pem = File.read!("priv/devices/MY_DEVICE_001/device_key.pem")
    cert_der = File.read!("priv/devices/MY_DEVICE_001/device_cert.der")
    private_key = X509.PrivateKey.from_pem!(key_pem)
    timestamp = DateTime.utc_now() |> DateTime.to_unix()
    signature = :public_key.sign("MY_DEVICE_001:#{timestamp}", :sha256, private_key)

    %{
      "serial" => "MY_DEVICE_001",
      "timestamp" => to_string(timestamp),
      "signature" => Base.encode64(signature),
      "cert" => Base.encode64(cert_der)
    }
  end

  # --- Verification item #9 ---

  test "send_command/3 pushes command event to connected device" do
    # Subscribe before joining so we catch the :device_online broadcast
    # that fires at the end of :after_join (after the command subscription is active).
    Phoenix.PubSub.subscribe(Shepherd.PubSub, "devices")

    {:ok, socket} = connect(ShepherdWeb.DeviceSocket, build_auth_params())
    {:ok, _reply, _socket} = join(socket, "device:MY_DEVICE_001")

    # :after_join is processed asynchronously; wait for its broadcast to
    # confirm the channel has subscribed to "device_commands:<id>".
    assert_receive {:device_online, device}

    Devices.send_command(device, "ping", %{"echo" => "hello"})

    assert_push "command", %{command: "ping", payload: %{"echo" => "hello"}}
  end

  # --- Verification item #10 ---

  test "revoked device is rejected at connection" do
    # First connection registers the device in the database.
    {:ok, _socket} = connect(ShepherdWeb.DeviceSocket, build_auth_params())

    # Revoke the device while it exists in the DB.
    device = Devices.get_device_by_serial("MY_DEVICE_001")
    {:ok, _} = Devices.revoke_device(device)

    # A subsequent connection attempt must be rejected —
    # ensure_registered returns {:error, :revoked} and the socket returns :error.
    assert :error = connect(ShepherdWeb.DeviceSocket, build_auth_params())
  end

  # --- Runtime revocation: device revoked while already connected ---

  test "revoking a connected device pushes revoked event and terminates the channel" do
    Phoenix.PubSub.subscribe(Shepherd.PubSub, "devices")

    {:ok, socket} = connect(ShepherdWeb.DeviceSocket, build_auth_params())
    {:ok, _reply, _socket} = join(socket, "device:MY_DEVICE_001")

    # Wait for :after_join to complete (command subscription is now active).
    assert_receive {:device_online, device}

    # Revoke while connected — triggers broadcast on device_commands topic.
    {:ok, _} = Devices.revoke_device(device)

    # Channel pushes "revoked" to the client before stopping.
    assert_push "revoked", %{}

    # terminate/2 marks the device offline and broadcasts :device_offline.
    assert_receive {:device_offline, _}
  end

  # --- Metrics ---

  describe "metrics" do
    setup do
      Phoenix.PubSub.subscribe(Shepherd.PubSub, "devices")
      {:ok, socket} = connect(ShepherdWeb.DeviceSocket, build_auth_params())
      {:ok, _reply, socket} = join(socket, "device:MY_DEVICE_001")

      # Wait for :after_join to complete
      assert_receive {:device_online, _device}

      {:ok, socket: socket}
    end

    test "ingests valid metrics", %{socket: socket} do
      metrics = [
        %{"name" => "cpu_temp", "value" => 45.5, "unit" => "celsius", "recorded_at" => System.system_time(:second)},
        %{"name" => "memory_percent", "value" => 62.3, "unit" => "percent", "recorded_at" => System.system_time(:second)}
      ]

      ref = push(socket, "metrics", %{"metrics" => metrics})
      assert_reply ref, :ok, %{ingested: 2}
    end

    test "returns count of valid metrics only", %{socket: socket} do
      metrics = [
        %{"name" => "valid", "value" => 1.0, "recorded_at" => System.system_time(:second)},
        %{"name" => "missing_value", "recorded_at" => System.system_time(:second)},
        %{"value" => 2.0, "recorded_at" => System.system_time(:second)}
      ]

      ref = push(socket, "metrics", %{"metrics" => metrics})
      assert_reply ref, :ok, %{ingested: 1}
    end

    test "rejects invalid payload structure", %{socket: socket} do
      ref = push(socket, "metrics", %{"invalid" => "payload"})
      assert_reply ref, :error, %{reason: "invalid_payload"}
    end

    test "rejects non-list metrics", %{socket: socket} do
      ref = push(socket, "metrics", %{"metrics" => "not a list"})
      assert_reply ref, :error, %{reason: "invalid_payload"}
    end
  end

  # --- Firmware Updates ---

  describe "update_status" do
    setup do
      Phoenix.PubSub.subscribe(Shepherd.PubSub, "devices")
      {:ok, socket} = connect(ShepherdWeb.DeviceSocket, build_auth_params())
      {:ok, _reply, socket} = join(socket, "device:MY_DEVICE_001")

      # Wait for :after_join to complete
      assert_receive {:device_online, device}

      {:ok, socket: socket, device: device}
    end

    test "handles update status events", %{socket: socket, device: device} do
      # Subscribe to update broadcasts
      Phoenix.PubSub.subscribe(Shepherd.PubSub, "device:#{device.id}:updates")

      ref = push(socket, "update_status", %{"status" => "downloading", "progress" => 50})
      assert_reply ref, :ok

      assert_receive {:update_status, %{"status" => "downloading", "progress" => 50}}
    end

    test "emits telemetry for update status", %{socket: socket, device: device} do
      test_pid = self()

      :telemetry.attach(
        "test-update-status",
        [:shepherd, :device, :update_status],
        fn _event, _measurements, metadata, _config ->
          send(test_pid, {:telemetry, metadata})
        end,
        nil
      )

      on_exit(fn -> :telemetry.detach("test-update-status") end)

      push(socket, "update_status", %{"status" => "applying", "progress" => 75})

      assert_receive {:telemetry, metadata}
      assert metadata.device_id == device.id
      assert metadata.status == "applying"
    end
  end
end
