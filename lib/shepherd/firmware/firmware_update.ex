defmodule Shepherd.Firmware.FirmwareUpdate do
  use Ecto.Schema
  import Ecto.Changeset

  @status_values [:pending, :downloading, :applying, :complete, :failed]

  schema "firmware_updates" do
    field :status, Ecto.Enum, values: @status_values, default: :pending
    field :started_at, :utc_datetime
    field :completed_at, :utc_datetime

    belongs_to :device, Shepherd.Devices.Device
    belongs_to :firmware, Shepherd.Firmware.FirmwareVersion

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(firmware_update, attrs) do
    firmware_update
    |> cast(attrs, [:device_id, :firmware_id, :status])
    |> validate_required([:device_id, :firmware_id])
    |> foreign_key_constraint(:device_id)
    |> foreign_key_constraint(:firmware_id)
  end

  @doc """
  Changeset for updating the status of a firmware update.
  Automatically manages started_at and completed_at timestamps.
  """
  def status_changeset(firmware_update, attrs) do
    changeset =
      firmware_update
      |> cast(attrs, [:status])
      |> validate_required([:status])
      |> validate_inclusion(:status, @status_values)

    status = get_change(changeset, :status)

    changeset
    |> maybe_set_started_at(firmware_update.started_at, status)
    |> maybe_set_completed_at(status)
  end

  # Set started_at when transitioning from pending to any other status
  defp maybe_set_started_at(changeset, nil, status)
       when status in [:downloading, :applying, :complete, :failed] do
    put_change(changeset, :started_at, DateTime.utc_now() |> DateTime.truncate(:second))
  end

  defp maybe_set_started_at(changeset, _started_at, _status), do: changeset

  # Set completed_at when reaching a terminal status
  defp maybe_set_completed_at(changeset, status) when status in [:complete, :failed] do
    put_change(changeset, :completed_at, DateTime.utc_now() |> DateTime.truncate(:second))
  end

  defp maybe_set_completed_at(changeset, _status), do: changeset
end
