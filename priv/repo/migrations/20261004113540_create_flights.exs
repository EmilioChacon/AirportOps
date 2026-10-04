defmodule AirportOps.Repo.Migrations.CreateFlights do
  use Ecto.Migration

  def change do
    create table(:flights) do
      add :flight_number, :string
      add :origin, :string
      add :destination, :string
      add :gate, :string
      add :scheduled_arrival, :utc_datetime
      add :scheduled_departure, :utc_datetime
      add :status, :string

      timestamps(type: :utc_datetime)
    end
  end
end
