defmodule AirportOpsWeb.PageController do
  use AirportOpsWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
