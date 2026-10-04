defmodule AirportOps.OperationsTest do
  use AirportOps.DataCase

  alias AirportOps.Operations

  describe "agents" do
    alias AirportOps.Operations.Agent

    import AirportOps.OperationsFixtures

    @invalid_attrs %{name: nil, role: nil}

    test "list_agents/0 returns all agents" do
      agent = agent_fixture()
      assert Operations.list_agents() == [agent]
    end

    test "get_agent!/1 returns the agent with given id" do
      agent = agent_fixture()
      assert Operations.get_agent!(agent.id) == agent
    end

    test "create_agent/1 with valid data creates a agent" do
      valid_attrs = %{name: "some name", role: "some role"}

      assert {:ok, %Agent{} = agent} = Operations.create_agent(valid_attrs)
      assert agent.name == "some name"
      assert agent.role == "some role"
    end

    test "create_agent/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Operations.create_agent(@invalid_attrs)
    end

    test "update_agent/2 with valid data updates the agent" do
      agent = agent_fixture()
      update_attrs = %{name: "some updated name", role: "some updated role"}

      assert {:ok, %Agent{} = agent} = Operations.update_agent(agent, update_attrs)
      assert agent.name == "some updated name"
      assert agent.role == "some updated role"
    end

    test "update_agent/2 with invalid data returns error changeset" do
      agent = agent_fixture()
      assert {:error, %Ecto.Changeset{}} = Operations.update_agent(agent, @invalid_attrs)
      assert agent == Operations.get_agent!(agent.id)
    end

    test "delete_agent/1 deletes the agent" do
      agent = agent_fixture()
      assert {:ok, %Agent{}} = Operations.delete_agent(agent)
      assert_raise Ecto.NoResultsError, fn -> Operations.get_agent!(agent.id) end
    end

    test "change_agent/1 returns a agent changeset" do
      agent = agent_fixture()
      assert %Ecto.Changeset{} = Operations.change_agent(agent)
    end
  end

  describe "flights" do
    alias AirportOps.Operations.Flight

    import AirportOps.OperationsFixtures

    @invalid_attrs %{status: nil, origin: nil, destination: nil, flight_number: nil, gate: nil, scheduled_arrival: nil, scheduled_departure: nil}

    test "list_flights/0 returns all flights" do
      flight = flight_fixture()
      assert Operations.list_flights() == [flight]
    end

    test "get_flight!/1 returns the flight with given id" do
      flight = flight_fixture()
      assert Operations.get_flight!(flight.id) == flight
    end

    test "create_flight/1 with valid data creates a flight" do
      valid_attrs = %{status: "some status", origin: "some origin", destination: "some destination", flight_number: "some flight_number", gate: "some gate", scheduled_arrival: ~U[2026-10-03 11:31:00Z], scheduled_departure: ~U[2026-10-03 11:31:00Z]}

      assert {:ok, %Flight{} = flight} = Operations.create_flight(valid_attrs)
      assert flight.status == "some status"
      assert flight.origin == "some origin"
      assert flight.destination == "some destination"
      assert flight.flight_number == "some flight_number"
      assert flight.gate == "some gate"
      assert flight.scheduled_arrival == ~U[2026-10-03 11:31:00Z]
      assert flight.scheduled_departure == ~U[2026-10-03 11:31:00Z]
    end

    test "create_flight/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Operations.create_flight(@invalid_attrs)
    end

    test "update_flight/2 with valid data updates the flight" do
      flight = flight_fixture()
      update_attrs = %{status: "some updated status", origin: "some updated origin", destination: "some updated destination", flight_number: "some updated flight_number", gate: "some updated gate", scheduled_arrival: ~U[2026-10-04 11:31:00Z], scheduled_departure: ~U[2026-10-04 11:31:00Z]}

      assert {:ok, %Flight{} = flight} = Operations.update_flight(flight, update_attrs)
      assert flight.status == "some updated status"
      assert flight.origin == "some updated origin"
      assert flight.destination == "some updated destination"
      assert flight.flight_number == "some updated flight_number"
      assert flight.gate == "some updated gate"
      assert flight.scheduled_arrival == ~U[2026-10-04 11:31:00Z]
      assert flight.scheduled_departure == ~U[2026-10-04 11:31:00Z]
    end

    test "update_flight/2 with invalid data returns error changeset" do
      flight = flight_fixture()
      assert {:error, %Ecto.Changeset{}} = Operations.update_flight(flight, @invalid_attrs)
      assert flight == Operations.get_flight!(flight.id)
    end

    test "delete_flight/1 deletes the flight" do
      flight = flight_fixture()
      assert {:ok, %Flight{}} = Operations.delete_flight(flight)
      assert_raise Ecto.NoResultsError, fn -> Operations.get_flight!(flight.id) end
    end

    test "change_flight/1 returns a flight changeset" do
      flight = flight_fixture()
      assert %Ecto.Changeset{} = Operations.change_flight(flight)
    end
  end

  describe "assignments" do
    alias AirportOps.Operations.Assignment

    import AirportOps.OperationsFixtures

    @invalid_attrs %{role: nil, shift_start: nil, shift_end: nil}

    test "list_assignments/0 returns all assignments" do
      assignment = assignment_fixture()
      assert Operations.list_assignments() == [assignment]
    end

    test "get_assignment!/1 returns the assignment with given id" do
      assignment = assignment_fixture()
      assert Operations.get_assignment!(assignment.id) == assignment
    end

    test "create_assignment/1 with valid data creates a assignment" do
      agent = agent_fixture()
      flight = flight_fixture()

      valid_attrs = %{
        agent_id: agent.id,
        flight_id: flight.id,
        role: "some role",
        shift_start: ~U[2026-10-03 11:43:00Z],
        shift_end: ~U[2026-10-03 13:43:00Z]
      }

      assert {:ok, %Assignment{} = assignment} = Operations.create_assignment(valid_attrs)
      assert assignment.role == "some role"
      assert assignment.shift_start == ~U[2026-10-03 11:43:00Z]
      assert assignment.shift_end == ~U[2026-10-03 13:43:00Z]
    end

    test "create_assignment/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Operations.create_assignment(@invalid_attrs)
    end

    test "create_assignment/1 rejects assignment violating 12-hour rest rule" do
      agent = agent_fixture()
      flight1 = flight_fixture()
      flight2 = flight_fixture()

      # First shift: 08:00 to 12:00
      assert {:ok, _} =
               Operations.create_assignment(%{
                 agent_id: agent.id,
                 flight_id: flight1.id,
                 role: "Marshaller",
                 shift_start: ~U[2026-10-03 08:00:00Z],
                 shift_end: ~U[2026-10-03 12:00:00Z]
               })

      # Second shift only 4 hours later (16:00): should fail!
      assert {:error, changeset} =
               Operations.create_assignment(%{
                 agent_id: agent.id,
                 flight_id: flight2.id,
                 role: "Baggage Handler",
                 shift_start: ~U[2026-10-03 16:00:00Z],
                 shift_end: ~U[2026-10-03 20:00:00Z]
               })

      assert %{shift_start: ["violates mandatory 12-hour rest period between shifts"]} =
               errors_on(changeset)
    end

    test "update_assignment/2 with valid data updates the assignment" do
      assignment = assignment_fixture()

      update_attrs = %{
        role: "some updated role",
        shift_start: ~U[2026-10-05 11:43:00Z],
        shift_end: ~U[2026-10-05 13:43:00Z]
      }

      assert {:ok, %Assignment{} = assignment} = Operations.update_assignment(assignment, update_attrs)
      assert assignment.role == "some updated role"
      assert assignment.shift_start == ~U[2026-10-05 11:43:00Z]
      assert assignment.shift_end == ~U[2026-10-05 13:43:00Z]
    end

    test "update_assignment/2 with invalid data returns error changeset" do
      assignment = assignment_fixture()
      assert {:error, %Ecto.Changeset{}} = Operations.update_assignment(assignment, @invalid_attrs)
      assert assignment == Operations.get_assignment!(assignment.id)
    end

    test "delete_assignment/1 deletes the assignment" do
      assignment = assignment_fixture()
      assert {:ok, %Assignment{}} = Operations.delete_assignment(assignment)
      assert_raise Ecto.NoResultsError, fn -> Operations.get_assignment!(assignment.id) end
    end

    test "change_assignment/1 returns a assignment changeset" do
      assignment = assignment_fixture()
      assert %Ecto.Changeset{} = Operations.change_assignment(assignment)
    end
  end
end
