defmodule Shepherd.Repo.Migrations.CreateFirmwareUpdates do
  use Ecto.Migration

  def change do
    execute(
      "CREATE TYPE firmware_update_status AS ENUM ('pending', 'downloading', 'applying', 'complete', 'failed')",
      "DROP TYPE firmware_update_status"
    )

    create table(:firmware_updates) do
      add :device_id, references(:devices, on_delete: :delete_all), null: false
      add :firmware_id, references(:firmwares, on_delete: :restrict), null: false
      add :status, :firmware_update_status, null: false, default: "pending"
      add :started_at, :utc_datetime
      add :completed_at, :utc_datetime
      timestamps(type: :utc_datetime)
    end

    create index(:firmware_updates, [:device_id])
    create index(:firmware_updates, [:firmware_id])
    create index(:firmware_updates, [:device_id, :inserted_at])
  end
end
