defmodule FinsaveWeb.Router do
  use FinsaveWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {FinsaveWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug FinsaveWeb.Plugs.Locale
    plug FinsaveWeb.Plugs.FetchCurrentUser
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", FinsaveWeb do
    pipe_through :browser

    get "/", PageController, :home
    get "/locale/:locale", LocaleController, :set
    post "/auth/log_in", SessionController, :create
    delete "/auth/log_out", SessionController, :delete
  end

  live_session :public,
    on_mount: [{FinsaveWeb.Hooks.Auth, :default}] do
    scope "/auth", FinsaveWeb do
      pipe_through :browser
      live "/login", AuthLive.Login, :new
      live "/register", AuthLive.Register, :new
    end
  end

  live_session :authenticated,
    on_mount: [
      {FinsaveWeb.Hooks.Auth, :default},
      {FinsaveWeb.Hooks.Auth, :require_authenticated_user}
    ] do
    scope "/", FinsaveWeb do
      pipe_through :browser
      live "/dashboard", DashboardLive.Index, :index
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", FinsaveWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:finsave, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: FinsaveWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  scope "/", FinsaveWeb do
    pipe_through :browser

    get "/*path", RedirectController, :to_login
  end
end
