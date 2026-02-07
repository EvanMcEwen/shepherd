defmodule Shepherd.Devices.Group do
  use Ecto.Schema
  import Ecto.Changeset

  schema "groups" do
    field :name, :string
    field :description, :string

    has_many :devices, Shepherd.Devices.Device
    belongs_to :current_firmware, Shepherd.Firmware.FirmwareVersion

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(group, attrs) do
    group
    |> cast(attrs, [:name, :description, :current_firmware_id])
    |> validate_required([:name])
    |> unique_constraint(:name)
    |> foreign_key_constraint(:current_firmware_id)
  end
end
