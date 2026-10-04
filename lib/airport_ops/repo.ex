defmodule AirportOps.Repo do
  use Ecto.Repo,
    otp_app: :airport_ops,
    adapter: Ecto.Adapters.Postgres
end
