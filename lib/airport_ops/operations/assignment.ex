defmodule AirportOps.Operations.Assignment do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, warn: false

  alias AirportOps.Operations.{Agent, Assignment, Flight}
  alias AirportOps.Repo

  schema "assignments" do
    field :role, :string
    field :shift_start, :utc_datetime
    field :shift_end, :utc_datetime

    # Associations
    belongs_to :agent, Agent
    belongs_to :flight, Flight

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(assignment, attrs) do
    assignment
    |> cast(attrs, [:role, :shift_start, :shift_end, :agent_id, :flight_id])
    |> validate_required([:role, :shift_start, :shift_end, :agent_id, :flight_id])
    |> validate_shift_order()
    |> validate_rest_period()
  end

  # Ensures end time is strictly after start time
  defp validate_shift_order(changeset) do
    start_time = get_field(changeset, :shift_start)
    end_time = get_field(changeset, :shift_end)

    if start_time && end_time && DateTime.compare(end_time, start_time) != :gt do
      add_error(changeset, :shift_end, "must be after shift start time")
    else
      changeset
    end
  end

  # Validates that an agent has at least 12 hours of rest between shifts
  defp validate_rest_period(changeset) do
    if changeset.valid? do
      agent_id = get_field(changeset, :agent_id)
      start_time = get_field(changeset, :shift_start)
      end_time = get_field(changeset, :shift_end)
      current_id = get_field(changeset, :id)

      min_allowed_start = DateTime.add(start_time, -12, :hour)
      max_allowed_end = DateTime.add(end_time, 12, :hour)

      # Query for any existing shift for this agent within 12 hours of the proposed shift
      query =
        from a in Assignment,
          where: a.agent_id == ^agent_id,
          where: a.shift_start < ^max_allowed_end and a.shift_end > ^min_allowed_start

      # Exclude current assignment if we are updating an existing one
      query =
        if current_id do
          where(query, [a], a.id != ^current_id)
        else
          query
        end

      if Repo.exists?(query) do
        add_error(
          changeset,
          :shift_start,
          "violates mandatory 12-hour rest period between shifts"
        )
      else
        changeset
      end
    else
      changeset
    end
  end
end
