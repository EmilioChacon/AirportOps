defmodule AirportOpsWeb.PageControllerTest do
  use AirportOpsWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Turnaround Roster Coordinator"
  end
end
