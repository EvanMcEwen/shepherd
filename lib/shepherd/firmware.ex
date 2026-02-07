defmodule Shepherd.Firmware do
  @moduledoc """
  The Firmware context.
  """

  import Ecto.Query, warn: false
  alias Shepherd.Repo

  alias Shepherd.Firmware.FirmwareVersion
  alias Shepherd.Firmware.FirmwareUpdate

  ## Firmware Versions

  @doc """
  Returns the list of firmwares.
  """
  def list_firmware do
    Repo.all(FirmwareVersion)
  end

  @doc """
  Returns the list of firmwares for a specific target, ordered by version descending.
  """
  def list_firmware_by_target(target) do
    FirmwareVersion
    |> where([f], f.target == ^target)
    |> order_by([f], desc: f.version)
    |> Repo.all()
  end

  @doc """
  Returns the list of firmwares for a specific target and application, ordered by version descending.
  """
  def list_firmware_by_target_and_application(target, application) do
    FirmwareVersion
    |> where([f], f.target == ^target and f.application == ^application)
    |> order_by([f], desc: f.version)
    |> Repo.all()
  end

  @doc """
  Gets the latest firmware for a specific target and application.
  """
  def get_latest_firmware(target, application) do
    FirmwareVersion
    |> where([f], f.target == ^target and f.application == ^application)
    |> order_by([f], desc: f.version)
    |> limit(1)
    |> Repo.one()
  end

  @doc """
  Gets a single firmware by id.
  """
  def get_firmware!(id), do: Repo.get!(FirmwareVersion, id)

  @doc """
  Gets a single firmware by SHA256 hash.
  """
  def get_firmware_by_sha256(sha256) do
    Repo.get_by(FirmwareVersion, sha256: sha256)
  end

  @doc """
  Gets a single firmware by target and version.
  """
  def get_firmware_by_target_and_version(target, version) do
    Repo.get_by(FirmwareVersion, target: target, version: version)
  end

  @doc """
  Finds firmware records by target and version where UUID is nil.
  Returns a list (may be empty or have multiple results).
  """
  def find_firmware_without_uuid(target, version) do
    FirmwareVersion
    |> where([f], f.target == ^target and f.version == ^version and is_nil(f.uuid))
    |> Repo.all()
  end

  @doc """
  Creates a firmware.
  """
  def create_firmware(attrs \\ %{}) do
    %FirmwareVersion{}
    |> FirmwareVersion.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a firmware.
  """
  def update_firmware(%FirmwareVersion{} = firmware, attrs) do
    firmware
    |> FirmwareVersion.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a firmware.
  """
  def delete_firmware(%FirmwareVersion{} = firmware) do
    Repo.delete(firmware)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking firmware changes.
  """
  def change_firmware(%FirmwareVersion{} = firmware, attrs \\ %{}) do
    FirmwareVersion.changeset(firmware, attrs)
  end

  ## Firmware Updates

  @doc """
  Creates a firmware update record.
  """
  def create_firmware_update(attrs \\ %{}) do
    %FirmwareUpdate{}
    |> FirmwareUpdate.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates the status of a firmware update.
  """
  def update_firmware_update_status(%FirmwareUpdate{} = firmware_update, attrs) do
    firmware_update
    |> FirmwareUpdate.status_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Gets the active (non-terminal) firmware update for a device.
  Returns nil if no active update exists.
  """
  def get_active_firmware_update(device_id) do
    FirmwareUpdate
    |> where([fu], fu.device_id == ^device_id)
    |> where([fu], fu.status in [:pending, :downloading, :applying])
    |> order_by([fu], desc: :inserted_at)
    |> limit(1)
    |> Repo.one()
  end

  @doc """
  Gets all firmware updates for a device, ordered by most recent first.
  """
  def list_firmware_updates_by_device(device_id) do
    FirmwareUpdate
    |> where([fu], fu.device_id == ^device_id)
    |> order_by([fu], desc: :inserted_at)
    |> preload(:firmware)
    |> Repo.all()
  end

  @doc """
  Gets the most recent successful firmware update for a device.
  """
  def get_current_firmware_version(device_id) do
    FirmwareUpdate
    |> where([fu], fu.device_id == ^device_id)
    |> where([fu], fu.status == :complete)
    |> order_by([fu], desc: :completed_at)
    |> limit(1)
    |> preload(:firmware)
    |> Repo.one()
    |> case do
      %FirmwareUpdate{firmware: firmware} -> firmware
      nil -> nil
    end
  end

  @doc """
  Gets the second most recent successful firmware version for a device.
  Used for rollback scenarios.
  """
  def get_previous_version(device_id) do
    FirmwareUpdate
    |> where([fu], fu.device_id == ^device_id)
    |> where([fu], fu.status == :complete)
    |> order_by([fu], desc: :completed_at)
    |> limit(2)
    |> preload(:firmware)
    |> Repo.all()
    |> case do
      [_current, %FirmwareUpdate{firmware: previous}] -> previous
      _ -> nil
    end
  end
end
