defmodule MolyWeb.Router do
  use MolyWeb, :router

  use AshAuthentication.Phoenix.Router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, html: {MolyWeb.Layouts, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
    plug(:load_from_session)
    plug(MolyWeb.Plugs.GeoBlocking, deny_countries: [])
  end

  pipeline :api do
    plug(:accepts, ["json"])
    plug(:load_from_bearer)
  end

  # scope "/", MolyWeb do
  # pipe_through(:browser)

  # ash_authentication_live_session :authenticated_routes do
  #   # in each liveview, add one of the following at the top of the module:
  #   #
  #   # If an authenticated user must be present:
  #   # on_mount {MolyWeb.LiveUserAuth, :live_user_required}
  #   #
  #   # If an authenticated user *may* be present:
  #   # on_mount {MolyWeb.LiveUserAuth, :live_user_optional}
  #   #
  #   # If an authenticated user must *not* be present:
  #   # on_mount {MolyWeb.LiveUserAuth, :live_no_user}
  # end

  # ash_authentication_live_session :authenticated_maybe_routes,
  #   on_mount: {MolyWeb.LiveUserAuth, :live_user_optional} do
  #   live("/", Affiliate.PageIndexLive)
  # end

  # ash_authentication_live_session :authenticated_routes,
  #   on_mount: {MolyWeb.LiveUserAuth, :live_user_required} do
  #   live("/products/submit", Affiliate.ProductSubmitLive)
  # end
  # end

  scope "/", MolyWeb do
    pipe_through(:browser)

    confirm_route(
      Moly.Accounts.User,
      :confirm_new_user,
      live_view: MolyWeb.Account.ConfirmNewUser,
      auth_routes_prefix: "/auth",
      path: "/auth/user/confirm_new_user",
      token_as_route_param?: false,
      layout: false
    )

    auth_routes(AuthController, Moly.Accounts.User, path: "/auth")
    sign_out_route(AuthController)

    ash_authentication_live_session :unauthenticated_routes,
      on_mount: {MolyWeb.LiveUserAuth, :live_no_user},
      session:
        {AshAuthentication.Phoenix.Router, :generate_session,
         [
           %{"auth_routes_prefix" => "/auth"}
         ]},
      layout: false do
      live("/sign-in", Account.SignInLive)
      live("/register", Account.SignUpLive)
      live("/reset", Account.ResetLive)
      live("/password-reset/:token", Account.PasswordResetLive)
    end
  end

  scope "/", MolyWeb do
    pipe_through([:browser])
    get("/sitemaps/:site_map_file", SitemapController, :show)
    get("/", PostController, :home)
    get("/post/:post_name", PostController, :view)

    get("/posts/:category_slug", PostController, :category)
    get("/tags/:tag_slug", PostController, :tag)

    post("/page/cf-validation", PageController, :cf_validation)
    post("/upload-file", PageController, :upload_file)

    live("/website/register-initial-user", Website.RegisterInitialUser)


    get("/about", PageController, :about)
    get("/contact", PageController, :contact)
    get("/privacy-policy", PageController, :privacy_policy)
    get("/terms-of-service", PageController, :terms_of_service)
  end

  #for youtubechannelhub
  scope "/", MolyWeb do
    pipe_through([:browser])
    get("/youtube-thumbnail-grabber", YoutubeChannelHub.PageController, :index)
    get("/youtube-income-estimator-pro", YoutubeChannelHub.PageController, :calculator)
    get("/youtube-tag-generator", YoutubeChannelHub.PageController, :tag_generator)
    post("/youtube-tag-generator-result", YoutubeChannelHub.PageController, :tag_generator_result)
  end

  scope "/admin", MolyWeb do
    pipe_through([:browser])

    ash_authentication_live_session :live_admin,
      on_mount: {MolyWeb.LiveUserAuth, :live_admin_required},
      root_layout: {MolyWeb.Layouts, :root_admin},
      layout: {MolyWeb.Layouts, :admin} do
      live("/dashboard", AdminDashboardLive)
      live("/users", AdminUserLive.Index, :index)
      live("/posts", AdminPostLive.Index, :index)
      live("/post/create", AdminPostLive.NewOrEdit)
      live("/post/:id/edit", AdminPostLive.NewOrEdit)
      live("/media", AdminMediaLive.Index, :index)
      live("/media/:id/edit", AdminMediaLive.Edit)
      live("/categories", AdminCategoryLive.Index, :index)
      live("/tags", AdminTagLive.Index, :index)
      live("/comments", AdminCommentLive.Index, :index)


      live("/pages", AdminPageLive.Index, :index)
      live("/page/create", AdminPageLive.Create, :create)
      live("/page/preview", AdminPageLive.Create, :preview)

      live("/website", AdminWebsiteLive.Index, :index)
      live("/website/basic", AdminWebsiteLive.Basic)
      live("/website/appearance", AdminWebsiteLive.Appearance)
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", MolyWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:moly, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through(:browser)

      live_dashboard("/dashboard", metrics: MolyWeb.Telemetry)
      forward("/mailbox", Plug.Swoosh.MailboxPreview)
    end
  end
end
