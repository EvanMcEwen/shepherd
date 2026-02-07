defmodule Shepherd.Repo.Migrations.CreateFirmwares do
  use Ecto.Migration

  def change do
    create table(:firmwares) do
      add :version, :string, null: false
      add :target, :string, null: false
      add :uuid, :string
      add :s3_key, :string, null: false
      add :sha256, :string, null: false
      add :size, :bigint
      add :metadata, :map, null: false, default: %{}
      timestamps(type: :utc_datetime)
    end

    create unique_index(:firmwares, [:sha256])
    create unique_index(:firmwares, [:target, :version])
    create index(:firmwares, [:target])
  end
end
