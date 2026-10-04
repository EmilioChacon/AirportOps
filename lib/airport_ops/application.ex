defmodule AirportOps.Application do
  # See https://elixir.hexdocs.pm/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      AirportOpsWeb.Telemetry,
      AirportOps.Repo,
      {DNSCluster, query: Application.get_env(:airport_ops, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: AirportOps.PubSub},
      # Start a worker by calling: AirportOps.Worker.start_link(arg)
      # {AirportOps.Worker, arg},
      # Start to serve requests, typically the last entry
      AirportOpsWeb.Endpoint
    ]

    # See https://elixir.hexdocs.pm/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: AirportOps.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    AirportOpsWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
