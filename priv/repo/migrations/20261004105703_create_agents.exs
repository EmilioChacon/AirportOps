defmodule AirportOps.Repo.Migrations.CreateAgents do
  use Ecto.Migration

  def change do
    create table(:agents) do
      add :name, :string
      add :role, :string

      timestamps(type: :utc_datetime)
    end
  end
end
