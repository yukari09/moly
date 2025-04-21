import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/moly start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.
if System.get_env("PHX_SERVER") do
  config :moly, MolyWeb.Endpoint, server: true
end

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

  config :moly, Moly.Repo,
    # ssl: true,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    socket_options: maybe_ipv6

  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "example.com"
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :moly, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  config :moly, MolyWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      # See the documentation on https://hexdocs.pm/bandit/Bandit.html#t:options/0
      # for details about using IPv6 vs IPv4 and loopback vs public addresses.
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ],
    secret_key_base: secret_key_base

  config :moly,
    token_signing_secret:
      System.get_env("TOKEN_SIGNING_SECRET") ||
        raise("Missing environment variable `TOKEN_SIGNING_SECRET`!")

  # ## SSL Support
  #
  # To get SSL working, you will need to add the `https` key
  # to your endpoint configuration:
  #
  #     config :moly, MolyWeb.Endpoint,
  #       https: [
  #         ...,
  #         port: 443,
  #         cipher_suite: :strong,
  #         keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
  #         certfile: System.get_env("SOME_APP_SSL_CERT_PATH")
  #       ]
  #
  # The `cipher_suite` is set to `:strong` to support only the
  # latest and more secure SSL ciphers. This means old browsers
  # and clients may not be supported. You can set it to
  # `:compatible` for wider support.
  #
  # `:keyfile` and `:certfile` expect an absolute path to the key
  # and cert in disk or a relative path inside priv, for example
  # "priv/ssl/server.key". For all supported SSL configuration
  # options, see https://hexdocs.pm/plug/Plug.SSL.html#configure/1
  #
  # We also recommend setting `force_ssl` in your config/prod.exs,
  # ensuring no data is ever sent via http, always redirecting to https:
  #
  #     config :moly, MolyWeb.Endpoint,
  #       force_ssl: [hsts: true]
  #
  # Check `Plug.SSL` for all available options in `force_ssl`.

  # ## Configuring the mailer
  #
  # In production you need to configure the mailer to use a different adapter.
  # Also, you may need to configure the Swoosh API client of your choice if you
  # are not using SMTP. Here is an example of the configuration:
  #

  # config :moly, Moly.Mailer,
  #   adapter: Swoosh.Adapters.Brevo,
  #   api_key: System.fetch_env!("BREVO_API_KEY")

  config :moly, Moly.Mailer,
    adapter: Resend.Swoosh.Adapter,
    api_key: System.fetch_env!("RESEND_API_KEY")

  #
  # For this example you need include a HTTP client required by Swoosh API client.
  # Swoosh supports Hackney and Finch out of the box:
  #
  # config :swoosh, :api_client, Swoosh.ApiClient.Finch
  #
  # See https://hexdocs.pm/swoosh/Swoosh.html#module-installation for details.
  # Customize env for this app
  config :moly,
    google_oauth2_client_id: System.get_env("GOOGLE_CLIENT_ID"),
    google_oauth2_redirect_uri: System.get_env("GOOGLE_REDIRECT_URI"),
    google_oauth2_client_secret: System.get_env("GOOGLE_CLIENT_SECRET"),
    email_name: System.get_env("EMAIL_NAME"),
    email_address: System.get_env("EMAIL_ADDRESS"),
    imagor_endpoint: System.get_env("IMAGOR_ENDPOINT"),
    imagor_secret: System.get_env("IMAGOR_SECRET"),
    email_group: System.get_env("EMAIL_GROUP"),
    cf_website_secret: System.get_env("CF_WEBSITE_SECRET"),
    cf_app_secret: System.get_env("CF_APP_SECRET"),
    team_name: "Affinew",
    support_email: "support@affinew.com"

  config :ex_aws,
    region: System.get_env("AWS_REGION"),
    access_key_id: System.get_env("AWS_ACCESS_KEY_ID"),
    secret_access_key: System.get_env("AWS_SECRET_ACCESS_KEY")

  config :ex_aws, :s3,
    scheme: System.get_env("S3_SCHEME"),
    host: System.get_env("S3_HOST"),
    port: String.to_integer(System.get_env("S3_PORT", "443")),
    bucket: System.get_env("S3_BUCKET")

  config :moly, Moly.Cluster,
    url: System.get_env("ES_HOST"),
    username: System.get_env("ES_USER"),
    password: System.get_env("ES_PASSWD"),
    prefix: System.get_env("PREFIX"),
    json_library: JSON,
    http_client_adapter:
      {Snap.HTTPClient.Adapters.Finch, [conn_opts: [transport_opts: [verify: :verify_none]]]}
end
