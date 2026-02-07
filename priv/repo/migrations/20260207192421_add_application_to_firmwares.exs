defmodule Shepherd.Repo.Migrations.AddApplicationToFirmwares do
  use Ecto.Migration

  def change do
    # Drop old unique constraint on target + version
    drop unique_index(:firmwares, [:target, :version])

    # Add application field
    alter table(:firmwares) do
      add :application, :string
    end

    # Create new unique constraint on target + application + version
    create unique_index(:firmwares, [:target, :application, :version])

    # Add index for querying by target + application
    create index(:firmwares, [:target, :application])
  end
end
