defmodule Shepherd.Devices.Device do
  use Ecto.Schema
  import Ecto.Changeset

  schema "devices" do
    field :serial, :string
    field :nickname, :string
    field :status, Ecto.Enum, values: [:online, :offline], default: :offline
    field :last_seen_at, :utc_datetime
    field :firmware_version, :string
    field :firmware_target, :string
    field :metadata, :map, default: %{}
    field :cert_fingerprint, :string
    field :cert_not_after, :utc_datetime
    field :revoked, :boolean, default: false

    belongs_to :group, Shepherd.Devices.Group

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(device, attrs) do
    device
    |> cast(attrs, [:serial, :nickname, :firmware_version, :firmware_target, :metadata, :group_id])
    |> validate_required([:serial])
    |> unique_constraint(:serial)
  end

  @doc "Changeset for fields set by the server during registration and reconnection."
  def registration_changeset(device, attrs) do
    device
    |> cast(attrs, [:serial, :cert_fingerprint, :cert_not_after])
    |> validate_required([:serial, :cert_fingerprint, :cert_not_after])
    |> unique_constraint(:serial)
  end

  @doc "Changeset for status updates (online/offline)."
  def status_changeset(device, attrs) do
    device
    |> cast(attrs, [:status, :last_seen_at])
    |> validate_required([:status])
  end
end
