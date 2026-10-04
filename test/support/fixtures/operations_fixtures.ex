defmodule AirportOps.OperationsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `AirportOps.Operations` context.
  """

  @doc """
  Generate a agent.
  """
  def agent_fixture(attrs \\ %{}) do
    {:ok, agent} =
      attrs
      |> Enum.into(%{
        name: "some name",
        role: "some role"
      })
      |> AirportOps.Operations.create_agent()

    agent
  end

  @doc """
  Generate a flight.
  """
  def flight_fixture(attrs \\ %{}) do
    {:ok, flight} =
      attrs
      |> Enum.into(%{
        destination: "some destination",
        flight_number: "some flight_number",
        gate: "some gate",
        origin: "some origin",
        scheduled_arrival: ~U[2026-10-03 11:31:00Z],
        scheduled_departure: ~U[2026-10-03 11:31:00Z],
        status: "some status"
      })
      |> AirportOps.Operations.create_flight()

    flight
  end

  @doc """
  Generate a assignment.
  """
  def assignment_fixture(attrs \\ %{}) do
    {:ok, assignment} =
      attrs
      |> Enum.into(%{
        role: "some role",
        shift_end: ~U[2026-10-03 11:43:00Z],
        shift_start: ~U[2026-10-03 11:43:00Z]
      })
      |> AirportOps.Operations.create_assignment()

    assignment
  end
end
