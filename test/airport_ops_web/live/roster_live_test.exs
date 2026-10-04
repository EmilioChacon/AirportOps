defmodule AirportOpsWeb.RosterLiveTest do
  use AirportOpsWeb.ConnCase
  import Phoenix.LiveViewTest
  import AirportOps.OperationsFixtures

  test "renders turnaround dashboard and live assignments stream", %{conn: conn} do
    assignment = assignment_fixture()

    {:ok, view, html} = live(conn, ~p"/")

    assert html =~ "Turnaround Roster Coordinator"
    assert html =~ "Live BEAM PubSub Connected"
    assert has_element?(view, "#assignments")
    assert has_element?(view, "#assignments-#{assignment.id}")
  end

  test "reassigning an agent via LiveView event updates the flight", %{conn: conn} do
    assignment = assignment_fixture()
    new_flight = flight_fixture(%{flight_number: "KL1234", gate: "D09"})

    {:ok, view, _html} = live(conn, ~p"/")

    view
    |> form("form[phx-change=reassign_flight]", %{
      "assignment-id" => assignment.id,
      "flight-id" => new_flight.id
    })
    |> render_change()

    assert render(view) =~ "Reassigned flight successfully!"
  end
end
