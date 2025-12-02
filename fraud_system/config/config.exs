import Config

config :fraud_system,
  ecto_repos: [FraudSystem.Repo]

config :fraud_system, FraudSystemWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [formats: [json: FraudSystemWeb.ErrorJSON], layout: false],
  pubsub_server: FraudSystem.PubSub,
  live_view: [signing_salt: "SECRET_SALT_CHANGE_ME"]

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason

import_config "#{config_env()}.exs"
