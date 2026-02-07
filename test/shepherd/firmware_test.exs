defmodule Shepherd.FirmwareTest do
  use Shepherd.DataCase

  alias Shepherd.Firmware
  alias Shepherd.Firmware.FirmwareVersion
  alias Shepherd.Firmware.FirmwareUpdate
  alias Shepherd.Devices.Device
  alias Shepherd.Repo

  @valid_firmware_attrs %{
    version: "1.2.3",
    target: "rpi5",
    application: "test_app",
    s3_key: "test_app/rpi5/1.2.3/test.fw",
    sha256: "abc123def456",
    size: 1024,
    metadata: %{"test" => "data"}
  }

  @valid_firmware_attrs_2 %{
    version: "1.2.4",
    target: "rpi5",
    application: "test_app",
    s3_key: "test_app/rpi5/1.2.4/test.fw",
    sha256: "xyz789abc123",
    size: 2048
  }

  defp create_device(attrs \\ %{}) do
    default = %{
      serial: "TEST-#{System.unique_integer([:positive])}",
      cert_fingerprint: "test_fingerprint",
      cert_not_after: DateTime.utc_now() |> DateTime.add(365, :day)
    }

    %Device{}
    |> Device.registration_changeset(Map.merge(default, attrs))
    |> Repo.insert!()
  end

  defp create_firmware(attrs \\ %{}) do
    attrs = Map.merge(@valid_firmware_attrs, attrs)
    {:ok, firmware} = Firmware.create_firmware(attrs)
    firmware
  end

  describe "firmware versions" do
    test "list_firmware/0 returns all firmwares" do
      firmware1 = create_firmware()
      firmware2 = create_firmware(%{version: "2.0.0", sha256: "different", s3_key: "test_app/rpi5/2.0.0/test.fw"})

      firmwares = Firmware.list_firmware()
      assert length(firmwares) == 2
      assert firmware1 in firmwares
      assert firmware2 in firmwares
    end

    test "list_firmware_by_target/1 filters by target" do
      rpi5_firmware = create_firmware(%{target: "rpi5"})

      _rpi4_firmware =
        create_firmware(%{target: "rpi4", sha256: "different", version: "2.0.0", s3_key: "test_app/rpi4/2.0.0/test.fw"})

      firmwares = Firmware.list_firmware_by_target("rpi5")
      assert length(firmwares) == 1
      assert hd(firmwares).id == rpi5_firmware.id
    end

    test "list_firmware_by_target_and_application/2 filters by both" do
      app1_firmware = create_firmware(%{application: "app1", sha256: "hash1"})

      _app2_firmware =
        create_firmware(%{
          application: "app2",
          sha256: "hash2",
          s3_key: "app2/rpi5/1.2.3/test.fw"
        })

      _different_target =
        create_firmware(%{
          target: "rpi4",
          application: "app1",
          sha256: "hash3",
          s3_key: "app1/rpi4/1.2.3/test.fw"
        })

      firmwares = Firmware.list_firmware_by_target_and_application("rpi5", "app1")
      assert length(firmwares) == 1
      assert hd(firmwares).id == app1_firmware.id
    end

    test "get_latest_firmware/2 returns most recent version" do
      _old = create_firmware(%{version: "1.0.0", sha256: "hash1", s3_key: "test_app/rpi5/1.0.0/test.fw"})
      latest = create_firmware(%{version: "2.0.0", sha256: "hash2", s3_key: "test_app/rpi5/2.0.0/test.fw"})

      result = Firmware.get_latest_firmware("rpi5", "test_app")
      assert result.id == latest.id
    end

    test "list_firmware_by_target/1 orders by version descending" do
      _fw1 = create_firmware(%{version: "1.0.0", sha256: "hash1", s3_key: "test_app/rpi5/1.0.0/test.fw"})
      _fw2 = create_firmware(%{version: "2.0.0", sha256: "hash2", s3_key: "test_app/rpi5/2.0.0/test.fw"})
      _fw3 = create_firmware(%{version: "1.5.0", sha256: "hash3", s3_key: "test_app/rpi5/1.5.0/test.fw"})

      firmwares = Firmware.list_firmware_by_target("rpi5")
      versions = Enum.map(firmwares, & &1.version)

      # Should be ordered: 2.0.0, 1.5.0, 1.0.0
      assert versions == ["2.0.0", "1.5.0", "1.0.0"]
    end

    test "get_firmware!/1 returns firmware by id" do
      firmware = create_firmware()
      found = Firmware.get_firmware!(firmware.id)
      assert found.id == firmware.id
      assert found.version == "1.2.3"
    end

    test "get_firmware_by_sha256/1 returns firmware by hash" do
      firmware = create_firmware()
      found = Firmware.get_firmware_by_sha256("abc123def456")
      assert found.id == firmware.id
    end

    test "get_firmware_by_sha256/1 returns nil when not found" do
      assert Firmware.get_firmware_by_sha256("nonexistent") == nil
    end

    test "get_firmware_by_target_and_version/1 returns firmware" do
      firmware = create_firmware()
      found = Firmware.get_firmware_by_target_and_version("rpi5", "1.2.3")
      assert found.id == firmware.id
    end

    test "get_firmware_by_target_and_version/1 returns nil when not found" do
      assert Firmware.get_firmware_by_target_and_version("rpi5", "9.9.9") == nil
    end

    test "create_firmware/1 creates firmware with valid attrs" do
      assert {:ok, firmware} = Firmware.create_firmware(@valid_firmware_attrs)
      assert firmware.version == "1.2.3"
      assert firmware.target == "rpi5"
      assert firmware.application == "test_app"
      assert firmware.s3_key == "test_app/rpi5/1.2.3/test.fw"
      assert firmware.sha256 == "abc123def456"
      assert firmware.size == 1024
      assert firmware.metadata == %{"test" => "data"}
    end

    test "create_firmware/1 requires version" do
      attrs = Map.delete(@valid_firmware_attrs, :version)
      assert {:error, changeset} = Firmware.create_firmware(attrs)
      assert "can't be blank" in errors_on(changeset).version
    end

    test "create_firmware/1 requires target" do
      attrs = Map.delete(@valid_firmware_attrs, :target)
      assert {:error, changeset} = Firmware.create_firmware(attrs)
      assert "can't be blank" in errors_on(changeset).target
    end

    test "create_firmware/1 requires s3_key" do
      attrs = Map.delete(@valid_firmware_attrs, :s3_key)
      assert {:error, changeset} = Firmware.create_firmware(attrs)
      assert "can't be blank" in errors_on(changeset).s3_key
    end

    test "create_firmware/1 requires sha256" do
      attrs = Map.delete(@valid_firmware_attrs, :sha256)
      assert {:error, changeset} = Firmware.create_firmware(attrs)
      assert "can't be blank" in errors_on(changeset).sha256
    end

    test "create_firmware/1 validates semver format" do
      attrs = Map.put(@valid_firmware_attrs, :version, "not-semver")
      assert {:error, changeset} = Firmware.create_firmware(attrs)
      assert "must be a valid semantic version (e.g., 1.2.3)" in errors_on(changeset).version
    end

    test "create_firmware/1 enforces unique sha256" do
      create_firmware()

      attrs = Map.merge(@valid_firmware_attrs, %{version: "2.0.0"})
      assert {:error, changeset} = Firmware.create_firmware(attrs)
      assert "has already been taken" in errors_on(changeset).sha256
    end

    test "create_firmware/1 enforces unique target+application+version" do
      create_firmware()

      attrs = Map.merge(@valid_firmware_attrs, %{sha256: "different_hash"})
      assert {:error, changeset} = Firmware.create_firmware(attrs)
      # The error might be on :target, :application, or :version depending on constraint
      errors = errors_on(changeset)

      assert Map.has_key?(errors, :target) or Map.has_key?(errors, :application) or
               Map.has_key?(errors, :version)
    end

    test "create_firmware/1 allows same version for different applications" do
      create_firmware(%{application: "app1", sha256: "hash1"})

      attrs =
        Map.merge(@valid_firmware_attrs, %{application: "app2", sha256: "hash2", s3_key: "app2/rpi5/1.2.3/test.fw"})

      assert {:ok, firmware} = Firmware.create_firmware(attrs)
      assert firmware.application == "app2"
    end

    test "update_firmware/2 updates firmware" do
      firmware = create_firmware()
      assert {:ok, updated} = Firmware.update_firmware(firmware, %{metadata: %{"new" => "value"}})
      assert updated.metadata == %{"new" => "value"}
    end

    test "delete_firmware/1 deletes firmware" do
      firmware = create_firmware()
      assert {:ok, _} = Firmware.delete_firmware(firmware)
      assert Firmware.get_firmware_by_sha256(firmware.sha256) == nil
    end

    test "change_firmware/1 returns changeset" do
      firmware = create_firmware()
      changeset = Firmware.change_firmware(firmware)
      assert %Ecto.Changeset{} = changeset
    end
  end

  describe "firmware updates" do
    setup do
      device = create_device()
      firmware = create_firmware()
      %{device: device, firmware: firmware}
    end

    test "create_firmware_update/1 creates update record", %{device: device, firmware: firmware} do
      assert {:ok, update} =
               Firmware.create_firmware_update(%{
                 device_id: device.id,
                 firmware_id: firmware.id
               })

      assert update.device_id == device.id
      assert update.firmware_id == firmware.id
      assert update.status == :pending
      assert update.started_at == nil
      assert update.completed_at == nil
    end

    test "create_firmware_update/1 requires device_id", %{firmware: firmware} do
      assert {:error, changeset} = Firmware.create_firmware_update(%{firmware_id: firmware.id})
      assert "can't be blank" in errors_on(changeset).device_id
    end

    test "create_firmware_update/1 requires firmware_id", %{device: device} do
      assert {:error, changeset} = Firmware.create_firmware_update(%{device_id: device.id})
      assert "can't be blank" in errors_on(changeset).firmware_id
    end

    test "update_firmware_update_status/2 sets started_at on first non-pending status", %{
      device: device,
      firmware: firmware
    } do
      {:ok, update} =
        Firmware.create_firmware_update(%{
          device_id: device.id,
          firmware_id: firmware.id
        })

      assert update.started_at == nil

      {:ok, updated} = Firmware.update_firmware_update_status(update, %{status: :downloading})

      assert updated.status == :downloading
      assert updated.started_at != nil
      assert updated.completed_at == nil
    end

    test "update_firmware_update_status/2 sets completed_at on terminal status", %{
      device: device,
      firmware: firmware
    } do
      {:ok, update} =
        Firmware.create_firmware_update(%{
          device_id: device.id,
          firmware_id: firmware.id
        })

      {:ok, updated} = Firmware.update_firmware_update_status(update, %{status: :complete})

      assert updated.status == :complete
      assert updated.started_at != nil
      assert updated.completed_at != nil
    end

    test "update_firmware_update_status/2 sets completed_at on failed status", %{
      device: device,
      firmware: firmware
    } do
      {:ok, update} =
        Firmware.create_firmware_update(%{
          device_id: device.id,
          firmware_id: firmware.id
        })

      {:ok, updated} = Firmware.update_firmware_update_status(update, %{status: :failed})

      assert updated.status == :failed
      assert updated.started_at != nil
      assert updated.completed_at != nil
    end

    test "update_firmware_update_status/2 progresses through statuses", %{
      device: device,
      firmware: firmware
    } do
      {:ok, update} =
        Firmware.create_firmware_update(%{
          device_id: device.id,
          firmware_id: firmware.id
        })

      {:ok, update} = Firmware.update_firmware_update_status(update, %{status: :downloading})
      assert update.status == :downloading
      assert update.started_at != nil
      assert update.completed_at == nil

      {:ok, update} = Firmware.update_firmware_update_status(update, %{status: :applying})
      assert update.status == :applying
      assert update.completed_at == nil

      {:ok, update} = Firmware.update_firmware_update_status(update, %{status: :complete})
      assert update.status == :complete
      assert update.completed_at != nil
    end

    test "get_active_firmware_update/1 returns pending update", %{
      device: device,
      firmware: firmware
    } do
      {:ok, update} =
        Firmware.create_firmware_update(%{
          device_id: device.id,
          firmware_id: firmware.id
        })

      found = Firmware.get_active_firmware_update(device.id)
      assert found.id == update.id
    end

    test "get_active_firmware_update/1 returns downloading update", %{
      device: device,
      firmware: firmware
    } do
      {:ok, update} =
        Firmware.create_firmware_update(%{
          device_id: device.id,
          firmware_id: firmware.id
        })

      {:ok, update} = Firmware.update_firmware_update_status(update, %{status: :downloading})

      found = Firmware.get_active_firmware_update(device.id)
      assert found.id == update.id
    end

    test "get_active_firmware_update/1 returns nil for completed update", %{
      device: device,
      firmware: firmware
    } do
      {:ok, update} =
        Firmware.create_firmware_update(%{
          device_id: device.id,
          firmware_id: firmware.id
        })

      {:ok, _} = Firmware.update_firmware_update_status(update, %{status: :complete})

      assert Firmware.get_active_firmware_update(device.id) == nil
    end

    test "get_active_firmware_update/1 returns nil for failed update", %{
      device: device,
      firmware: firmware
    } do
      {:ok, update} =
        Firmware.create_firmware_update(%{
          device_id: device.id,
          firmware_id: firmware.id
        })

      {:ok, _} = Firmware.update_firmware_update_status(update, %{status: :failed})

      assert Firmware.get_active_firmware_update(device.id) == nil
    end

    test "list_firmware_updates_by_device/1 returns all updates for device", %{
      device: device,
      firmware: firmware
    } do
      {:ok, update1} =
        Firmware.create_firmware_update(%{
          device_id: device.id,
          firmware_id: firmware.id
        })

      firmware2 = create_firmware(@valid_firmware_attrs_2)

      {:ok, update2} =
        Firmware.create_firmware_update(%{
          device_id: device.id,
          firmware_id: firmware2.id
        })

      updates = Firmware.list_firmware_updates_by_device(device.id)
      assert length(updates) == 2

      # Should be ordered by most recent first (later inserted_at comes first)
      # Check that update2 was created after update1 and appears first
      assert Enum.any?(updates, &(&1.id == update1.id))
      assert Enum.any?(updates, &(&1.id == update2.id))
      # The first element should be the more recently inserted one
      assert DateTime.compare(hd(updates).inserted_at, Enum.at(updates, 1).inserted_at) in [:gt, :eq]
    end

    test "get_current_firmware_version/1 returns most recent complete version", %{
      device: device
    } do
      firmware1 = create_firmware(%{version: "1.0.0", sha256: "hash1"})

      {:ok, update1} =
        Firmware.create_firmware_update(%{
          device_id: device.id,
          firmware_id: firmware1.id
        })

      {:ok, _} = Firmware.update_firmware_update_status(update1, %{status: :complete})

      # Ensure different completed_at timestamps
      Process.sleep(1100)

      firmware2 = create_firmware(%{version: "2.0.0", sha256: "hash2"})

      {:ok, update2} =
        Firmware.create_firmware_update(%{
          device_id: device.id,
          firmware_id: firmware2.id
        })

      {:ok, _} = Firmware.update_firmware_update_status(update2, %{status: :complete})

      current = Firmware.get_current_firmware_version(device.id)
      assert current.id == firmware2.id
    end

    test "get_current_firmware_version/1 returns nil when no complete updates", %{
      device: device,
      firmware: firmware
    } do
      {:ok, _} =
        Firmware.create_firmware_update(%{
          device_id: device.id,
          firmware_id: firmware.id
        })

      assert Firmware.get_current_firmware_version(device.id) == nil
    end

    test "get_previous_version/1 returns second most recent complete version", %{
      device: device
    } do
      firmware1 = create_firmware(%{version: "1.0.0", sha256: "hash1"})

      {:ok, update1} =
        Firmware.create_firmware_update(%{
          device_id: device.id,
          firmware_id: firmware1.id
        })

      {:ok, _} = Firmware.update_firmware_update_status(update1, %{status: :complete})

      # Ensure different completed_at timestamps
      Process.sleep(1100)

      firmware2 = create_firmware(%{version: "2.0.0", sha256: "hash2"})

      {:ok, update2} =
        Firmware.create_firmware_update(%{
          device_id: device.id,
          firmware_id: firmware2.id
        })

      {:ok, _} = Firmware.update_firmware_update_status(update2, %{status: :complete})

      previous = Firmware.get_previous_version(device.id)
      assert previous.id == firmware1.id
    end

    test "get_previous_version/1 returns nil when only one complete update", %{
      device: device,
      firmware: firmware
    } do
      {:ok, update} =
        Firmware.create_firmware_update(%{
          device_id: device.id,
          firmware_id: firmware.id
        })

      {:ok, _} = Firmware.update_firmware_update_status(update, %{status: :complete})

      assert Firmware.get_previous_version(device.id) == nil
    end

    test "get_previous_version/1 returns nil when no complete updates", %{device: device} do
      assert Firmware.get_previous_version(device.id) == nil
    end
  end

  describe "firmware deletion with foreign key constraints" do
    test "cannot delete firmware that has been deployed" do
      device = create_device()
      firmware = create_firmware()

      {:ok, _update} =
        Firmware.create_firmware_update(%{
          device_id: device.id,
          firmware_id: firmware.id
        })

      # Should fail due to on_delete: :restrict constraint
      assert_raise Postgrex.Error, fn ->
        Firmware.delete_firmware(firmware)
      end
    end

    test "deleting device cascades to firmware_updates" do
      device = create_device()
      firmware = create_firmware()

      {:ok, update} =
        Firmware.create_firmware_update(%{
          device_id: device.id,
          firmware_id: firmware.id
        })

      # Delete device
      Repo.delete!(device)

      # firmware_update should be deleted (on_delete: :delete_all)
      assert Repo.get(FirmwareUpdate, update.id) == nil

      # firmware should still exist
      assert Repo.get(FirmwareVersion, firmware.id) != nil
    end
  end
end
