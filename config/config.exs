# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :ash,
  include_embedded_source_by_default?: false,
  default_page_type: :keyset,
  policies: [no_filter_static_forbidden_reads?: false],
  show_keysets_for_all_actions?: false

config :ash, :policies, show_policy_breakdowns?: true, no_filter_static_forbidden_reads?: false

config :spark,
  formatter: [
    remove_parens?: true,
    "Ash.Resource": [
      section_order: [
        :authentication,
        :tokens,
        :postgres,
        :resource,
        :code_interface,
        :actions,
        :policies,
        :pub_sub,
        :preparations,
        :changes,
        :validations,
        :multitenancy,
        :attributes,
        :relationships,
        :calculations,
        :aggregates,
        :identities
      ]
    ],
    "Ash.Domain": [section_order: [:resources, :policies, :authorization, :domain, :execution]]
  ]

config :moly,
  ecto_repos: [Moly.Repo],
  generators: [timestamp_type: :utc_datetime],
  ash_domains: [
    Moly.Contents,
    Moly.Accounts,
    Moly.Comments,
    Moly.Options,
    Moly.Terms
  ]

# Configures the endpoint
config :moly, MolyWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: MolyWeb.ErrorHTML, json: MolyWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Moly.PubSub,
  live_view: [signing_salt: "IYjR+2Ds"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :moly, Moly.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.25.1",
  moly: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "4.0.0",
  moly: [
    args: ~w(
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# ,
# admin: [
#   args: ~w(
#     --config=tailwind.admin.config.js
#     --input=css/admin.css
#     --output=../priv/static/assets/admin.css
#   ),
#   cd: Path.expand("../assets", __DIR__)
# ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, JSON

config :moly, Oban,
  repo: Moly.Repo,
  queues: [mailers: 20],
  plugins: [
    {Oban.Plugins.Cron,
      crontab: [
        {"@daily", Moly.Affinew.Workers.Sitemap}
      ]
    }
  ]

config :moly, :env, config_env()
# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
