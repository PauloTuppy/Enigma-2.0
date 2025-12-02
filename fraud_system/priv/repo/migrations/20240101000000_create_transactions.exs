defmodule FraudSystem.Repo.Migrations.CreateTransactions do
  use Ecto.Migration

  def change do
    create table(:transactions, primary_key: {:id, :binary_id, autogenerate: true}) do
      add :transaction_id, :string, null: false
      add :user_id, :string, null: false
      add :account_age_days, :integer, default: 0
      add :amount_brl, :decimal, null: false
      add :currency, :string, default: "BRL"
      add :balance_before_brl, :decimal
      add :balance_after_brl, :decimal

      # Contexto da aposta
      add :bet_site, :string
      add :bet_type, :string  # sports, casino, slots
      add :game_category, :string

      # Origem e device
      add :country, :string, default: "BR"
      add :ip_address, :string
      add :ip_risk_score, :float, default: 0.0
      add :device_fingerprint, :string
      add :device_trust_score, :float, default: 0.5

      # Comportamento
      add :txn_count_24h, :integer, default: 0
      add :failed_logins_24h, :integer, default: 0
      add :failed_withdrawals_24h, :integer, default: 0
      add :chargebacks_90d, :integer, default: 0
      add :avg_amount_7d, :decimal
      add :max_amount_7d, :decimal

      # Pagamento
      add :payment_method, :string
      add :payment_provider, :string
      add :withdraw_requested, :boolean, default: false
      add :withdraw_amount_brl, :decimal
      add :withdraw_status, :string

      # Resultados da Análise
      add :fraud_score, :float
      add :fraud_status, :string
      add :fraud_reason, :string
      add :processed_at, :utc_datetime

      timestamps()
    end

    create unique_index(:transactions, [:transaction_id])
    create index(:transactions, [:user_id])
    create index(:transactions, [:fraud_status])
  end
end
