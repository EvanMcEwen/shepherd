defmodule Shepherd.Repo.Migrations.CreateDevices do
  use Ecto.Migration

  def change do
    execute(
      "CREATE TYPE status AS ENUM ('online', 'offline')",
      "DROP TYPE status"
    )

    create table(:devices) do
      add :serial, :string, null: false
      add :nickname, :string
      add :status, :status, null: false, default: "offline"
      add :last_seen_at, :utc_datetime
      add :firmware_version, :string
      add :firmware_target, :string
      add :metadata, :map, null: false, default: %{}
      add :cert_fingerprint, :string
      add :cert_not_after, :utc_datetime
      add :revoked, :boolean, null: false, default: false
      add :group_id, references(:groups, type: :id, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:devices, [:serial])
    create index(:devices, [:status])
    create index(:devices, [:group_id])
  end
end
