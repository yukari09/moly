import Config
config :moly, Oban, testing: :manual
config :moly, token_signing_secret: "rMReAXZnWynPngElyZK8DM1RugQ9UufE"
config :ash, disable_async?: true
config :ash, :missed_notifications, :ignore

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :moly, Moly.Repo,
  username: "yukari",
  password: "83233167",
  hostname: "localhost",
  database: "moly_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :moly, MolyWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "8/oqWuTL6G8eHlSA4WUaaxo393E6gxfV/PlDOGRNCoNa1V/F8avp9v35Ve8O2t5E",
  server: false

# In test we don't send emails
config :moly, Moly.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true
