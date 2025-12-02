import Config

# Configure your database
config :fraud_system, FraudSystem.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "fraud_system_dev",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

# For development, we disable any cache and enable
# debugging and code reloading.
config :fraud_system, FraudSystemWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "SECRET_KEY_BASE_DEV_CHANGE_ME_PLEASE_1234567890",
  watchers: []

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime

# Kafka Configuration (Confluent Cloud)
config :fraud_system, :kafka,
  hosts: [System.get_env("CONFLUENT_BOOTSTRAP_SERVERS") || "localhost:9092"],
  group_id: "fraud-enigma-group",
  topics: ["bets-transactions"],
  sasl_username: System.get_env("CONFLUENT_SASL_USERNAME"),
  sasl_password: System.get_env("CONFLUENT_SASL_PASSWORD")

# Vertex AI (Goth)
config :goth,
  json: System.get_env("GOOGLE_APPLICATION_CREDENTIALS") |> File.read!()

config :fraud_system, :vertex_ai,
  project_id: System.get_env("GCP_PROJECT_ID"),
  location: "us-central1",
  endpoint_id: System.get_env("VERTEX_ENDPOINT_ID")
