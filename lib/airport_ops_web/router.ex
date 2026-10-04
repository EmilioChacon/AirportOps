defmodule AirportOpsWeb.Router do
  use AirportOpsWeb, :router
  import Plug.BasicAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {AirportOpsWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    
    if Mix.env() != :test do
      plug :basic_auth, 
        username: System.get_env("AUTH_USER") || "admin", 
        password: System.get_env("AUTH_PASS") || "demo123"
    end
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", AirportOpsWeb do
    pipe_through :browser

    live "/", RosterLive, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", AirportOpsWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:airport_ops, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: AirportOpsWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
