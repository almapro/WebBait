defmodule WebBaitWeb.Router do
  use WebBaitWeb, :router

  import WebBaitWeb.UserAuth

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, {WebBaitWeb.LayoutView, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
    plug(:fetch_current_user)
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  # Other scopes may use custom stacks.
  scope "/api", WebBaitWeb do
    pipe_through :api
    post "/agents", AgentController, :create
    post "/agents/token", AgentController, :token
  end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through(:browser)

      live_dashboard("/live_dashboard", metrics: WebBaitWeb.Telemetry)
    end
  end

  ## Authentication routes

  scope "/", WebBaitWeb do
    pipe_through([:browser, :redirect_if_user_is_authenticated])

    get("/", UserSessionController, :new)
    post("/", UserSessionController, :create)
  end

  scope "/", WebBaitWeb do
    pipe_through([:browser, :require_authenticated_user])

    live("/dashboard", MainLive.Index, :index)
    live("/settings", SettingsLive.Index, :index)
    live("/users", UsersLive.Users, :index)
    live("/users/new", UsersLive.Users, :new)
    live("/users/delete/:id", UsersLive.Users, :delete)
    live "/agents", AgentLive.Index, :index
    live "/agents/:id", AgentLive.Webrtc, :index
    live "/agents/:id/theater", AgentLive.Webrtc, :theater
    live "/agents/:id/commands", AgentLive.Commands, :index
    live "/agents/:id/activities", AgentLive.Activities, :index
  end

  scope "/", WebBaitWeb do
    pipe_through([:browser])

    delete("/logout", UserSessionController, :delete)
  end
end
