defmodule FraudSystem.FraudAlerts.FraudAlert do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "fraud_alerts" do
    field :alert_type, :string
    field :severity, :string
    field :status, :string, default: "open"
    field :details, :map
    
    belongs_to :transaction, FraudSystem.Transactions.Transaction

    timestamps()
  end

  @doc false
  def changeset(fraud_alert, attrs) do
    fraud_alert
    |> cast(attrs, [:alert_type, :severity, :status, :details, :transaction_id])
    |> validate_required([:alert_type, :severity, :transaction_id])
  end
end
