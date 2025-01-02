defmodule MonorepoWeb.Router do
  use MonorepoWeb, :router

  use AshAuthentication.Phoenix.Router

  # import AshAdmin.Router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, html: {MonorepoWeb.Layouts, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
    plug(:load_from_session)
  end

  pipeline :api do
    plug(:accepts, ["json"])
    plug(:load_from_bearer)
  end

  scope "/", MonorepoWeb do
    pipe_through(:browser)

    ash_authentication_live_session :authenticated_routes do
      # in each liveview, add one of the following at the top of the module:
      #
      # If an authenticated user must be present:
      # on_mount {MonorepoWeb.LiveUserAuth, :live_user_required}
      #
      # If an authenticated user *may* be present:
      # on_mount {MonorepoWeb.LiveUserAuth, :live_user_optional}
      #
      # If an authenticated user must *not* be present:
      # on_mount {MonorepoWeb.LiveUserAuth, :live_no_user}
    end
  end

  scope "/", MonorepoWeb do
    pipe_through(:browser)

    get("/", PageController, :home)
    auth_routes(AuthController, Monorepo.Accounts.User, path: "/auth")
    sign_out_route(AuthController)

    # Remove these if you'd like to use your own authentication views
    sign_in_route(
      register_path: "/register",
      reset_path: "/reset",
      auth_routes_prefix: "/auth",
      on_mount: [{MonorepoWeb.LiveUserAuth, :live_no_user}],
      overrides: [
        MonorepoWeb.AuthOverrides,
        AshAuthentication.Phoenix.Overrides.Default
      ]
    )

    # Remove this if you do not want to use the reset password feature
    reset_route(
      auth_routes_prefix: "/auth",
      overrides: [
        MonorepoWeb.AuthOverrides,
        AshAuthentication.Phoenix.Overrides.Default
      ]
    )
  end

  # scope "/" do
  #   # Pipe it through your browser pipeline
  #   pipe_through [:browser]

  #   ash_admin "/admin"
  # end

  scope "/admin", MonorepoWeb do
    pipe_through(:browser)

    ash_authentication_live_session :live_admin,
      on_mount: {MonorepoWeb.LiveUserAuth, :live_admin_required},
      layout: {MonorepoWeb.Layouts, :admin} do
      live("/dashboard", AdminDashboardLive)
      live("/users", AdminUserLive.Index, :index)
      live("/posts/new", AdminPostLive.New)
      live("/media", AdminMediaLive.Index, :index)
      live("/media/:id/edit", AdminMediaLive.Edit)
      # live "/categories", CategoryLive.Index, :index
      # live "/tags", TagLive.Index, :index
      # live "/posts", PostLive.Index, :index
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", MonorepoWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:monorepo, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through(:browser)

      live_dashboard("/dashboard", metrics: MonorepoWeb.Telemetry)
      forward("/mailbox", Plug.Swoosh.MailboxPreview)
    end
  end
end
