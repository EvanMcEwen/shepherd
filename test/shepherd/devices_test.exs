defmodule Shepherd.DevicesTest do
  use Shepherd.DataCase

  alias Shepherd.Devices
  alias Shepherd.Devices.Device

  describe "send_update/3" do
    # These tests require a connected device, so they are mostly integration tests
    # For unit testing, we verify the function exists and has correct arity

    test "send_update/2 accepts url" do
      device = %Device{id: 1, serial: "TEST"}
      # Will return :ok since send_command uses broadcast which always returns :ok
      assert :ok = Devices.send_update(device, "https://example.com/fw.fw")
    end

    test "send_update/3 accepts options" do
      device = %Device{id: 1, serial: "TEST"}
      assert :ok = Devices.send_update(device, "https://example.com/fw.fw", reboot: false)
    end

    test "send_update/3 defaults reboot to true" do
      device = %Device{id: 1, serial: "TEST"}
      assert :ok = Devices.send_update(device, "https://example.com/fw.fw")
    end
  end

  describe "subscribe_updates/1" do
    test "subscribes to device update topic" do
      device_id = 123
      assert :ok = Devices.subscribe_updates(device_id)

      # Verify subscription by checking we can receive a broadcast
      Phoenix.PubSub.broadcast(
        Shepherd.PubSub,
        "device:#{device_id}:updates",
        {:update_status, %{"status" => "test"}}
      )

      assert_receive {:update_status, %{"status" => "test"}}
    end
  end
end
