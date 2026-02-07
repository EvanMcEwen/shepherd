import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :shepherd, Shepherd.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "shepherd_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :shepherd, ShepherdWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "OFFK8305IapeEQmuKALwEiVA2k3idrLsil07pCLBWRFv9AKWFE8tYjuWMJTnzzWH",
  server: false

# In test we don't send emails
config :shepherd, Shepherd.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true

# Sort query params output of verified routes for robust url comparisons
config :phoenix,
  sort_verified_routes_query_params: true

# Fleet CA certificate for device authentication in tests
config :shepherd, :fleet_ca_pem, File.read!("priv/ca/fleet_ca.pem")

# S3 configuration is in config/runtime.exs (evaluated at runtime)
