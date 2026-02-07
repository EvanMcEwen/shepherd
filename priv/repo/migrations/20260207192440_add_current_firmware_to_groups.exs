defmodule Shepherd.Repo.Migrations.AddCurrentFirmwareToGroups do
  use Ecto.Migration

  def change do
    alter table(:groups) do
      add :current_firmware_id, references(:firmwares, on_delete: :nilify_all)
    end

    create index(:groups, [:current_firmware_id])
  end
end
