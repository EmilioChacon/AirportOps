defmodule AirportOps.Repo.Migrations.CreateAssignments do
  use Ecto.Migration

  def change do
    create table(:assignments) do
      add :role, :string
      add :shift_start, :utc_datetime
      add :shift_end, :utc_datetime
      add :agent_id, references(:agents, on_delete: :nothing)
      add :flight_id, references(:flights, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:assignments, [:agent_id])
    create index(:assignments, [:flight_id])
  end
end
