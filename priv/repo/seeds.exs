# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
alias AirportOps.Operations
alias AirportOps.Repo

# Clean existing data for idempotency
Repo.delete_all(AirportOps.Operations.Assignment)
Repo.delete_all(AirportOps.Operations.Flight)
Repo.delete_all(AirportOps.Operations.Agent)

now = DateTime.utc_now() |> DateTime.truncate(:second)

# 1. Create Ground Agents
{:ok, a1} = Operations.create_agent(%{name: "Elena Rostova", role: "Ramp Lead"})
{:ok, a2} = Operations.create_agent(%{name: "Marcus Vance", role: "Marshaller"})
{:ok, a3} = Operations.create_agent(%{name: "Carlos Gomez", role: "Baggage Handler"})
{:ok, a4} = Operations.create_agent(%{name: "Amina Al-Mansoor", role: "Fueler"})
{:ok, a5} = Operations.create_agent(%{name: "Liam O'Connor", role: "Baggage Handler"})

# 2. Create Turnaround Flights
{:ok, f1} =
  Operations.create_flight(%{
    flight_number: "IB3421",
    origin: "MAD",
    destination: "LHR",
    gate: "B12",
    scheduled_arrival: DateTime.add(now, -30, :minute),
    scheduled_departure: DateTime.add(now, 45, :minute),
    status: "turnaround"
  })

{:ok, f2} =
  Operations.create_flight(%{
    flight_number: "LH1802",
    origin: "MUC",
    destination: "MAD",
    gate: "C04",
    scheduled_arrival: DateTime.add(now, 15, :minute),
    scheduled_departure: DateTime.add(now, 90, :minute),
    status: "on_block"
  })

{:ok, f3} =
  Operations.create_flight(%{
    flight_number: "AF1400",
    origin: "CDG",
    destination: "MAD",
    gate: "A08",
    scheduled_arrival: DateTime.add(now, 60, :minute),
    scheduled_departure: DateTime.add(now, 140, :minute),
    status: "scheduled"
  })

# 3. Create Initial Shift Assignments (with valid rest intervals!)
{:ok, _} =
  Operations.create_assignment(%{
    agent_id: a1.id,
    flight_id: f1.id,
    role: "Ramp Lead",
    shift_start: DateTime.add(now, -30, :minute),
    shift_end: DateTime.add(now, 45, :minute)
  })

{:ok, _} =
  Operations.create_assignment(%{
    agent_id: a2.id,
    flight_id: f1.id,
    role: "Marshaller",
    shift_start: DateTime.add(now, -30, :minute),
    shift_end: DateTime.add(now, 45, :minute)
  })

{:ok, _} =
  Operations.create_assignment(%{
    agent_id: a3.id,
    flight_id: f1.id,
    role: "Baggage Handler",
    shift_start: DateTime.add(now, -30, :minute),
    shift_end: DateTime.add(now, 45, :minute)
  })

IO.puts("Successfully seeded AirportOps data:")
IO.puts("  * 5 Ground Crew Agents")
IO.puts("  * 3 Turnaround Flights (IB3421, LH1802, AF1400)")
IO.puts("  * 3 Active Turnaround Shift Assignments")
