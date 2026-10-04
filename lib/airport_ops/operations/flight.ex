defmodule AirportOps.Operations.Flight do
  use Ecto.Schema
  import Ecto.Changeset

  schema "flights" do
    field :flight_number, :string
    field :origin, :string
    field :destination, :string
    field :gate, :string
    field :scheduled_arrival, :utc_datetime
    field :scheduled_departure, :utc_datetime
    field :status, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(flight, attrs) do
    flight
    |> cast(attrs, [
      :flight_number,
      :origin,
      :destination,
      :gate,
      :scheduled_arrival,
      :scheduled_departure,
      :status
    ])
    |> validate_required([
      :flight_number,
      :origin,
      :destination,
      :gate,
      :scheduled_arrival,
      :scheduled_departure,
      :status
    ])
  end
end
