defmodule FraudSystem.Transactions.Transaction do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "transactions" do
    field :transaction_id, :string
    field :user_id, :string
    field :account_age_days, :integer
    field :amount_brl, :decimal
    field :currency, :string, default: "BRL"
    field :balance_before_brl, :decimal
    field :balance_after_brl, :decimal

    field :bet_site, :string
    field :bet_type, :string
    field :game_category, :string

    field :country, :string
    field :ip_address, :string
    field :ip_risk_score, :float
    field :device_fingerprint, :string
    field :device_trust_score, :float

    field :txn_count_24h, :integer
    field :failed_logins_24h, :integer
    field :failed_withdrawals_24h, :integer
    field :chargebacks_90d, :integer
    field :avg_amount_7d, :decimal
    field :max_amount_7d, :decimal

    field :payment_method, :string
    field :payment_provider, :string
    field :withdraw_requested, :boolean
    field :withdraw_amount_brl, :decimal
    field :withdraw_status, :string

    field :fraud_score, :float
    field :fraud_status, :string
    field :fraud_reason, :string
    field :processed_at, :utc_datetime

    timestamps()
  end

  @doc false
  def changeset(transaction, attrs) do
    transaction
    |> cast(attrs, [
      :transaction_id, :user_id, :account_age_days, :amount_brl, :currency,
      :balance_before_brl, :balance_after_brl, :bet_site, :bet_type, :game_category,
      :country, :ip_address, :ip_risk_score, :device_fingerprint, :device_trust_score,
      :txn_count_24h, :failed_logins_24h, :failed_withdrawals_24h, :chargebacks_90d,
      :avg_amount_7d, :max_amount_7d, :payment_method, :payment_provider,
      :withdraw_requested, :withdraw_amount_brl, :withdraw_status,
      :fraud_score, :fraud_status, :fraud_reason, :processed_at
    ])
    |> validate_required([:transaction_id, :user_id, :amount_brl])
    |> unique_constraint(:transaction_id)
  end
end
