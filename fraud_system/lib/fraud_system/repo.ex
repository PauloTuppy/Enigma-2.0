defmodule FraudSystem.Repo do
  use Ecto.Repo,
    otp_app: :fraud_system,
    adapter: Ecto.Adapters.Postgres
end
