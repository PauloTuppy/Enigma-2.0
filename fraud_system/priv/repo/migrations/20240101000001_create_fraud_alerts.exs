defmodule FraudSystem.Repo.Migrations.CreateFraudAlerts do
  use Ecto.Migration

  def change do
    create table(:fraud_alerts, primary_key: {:id, :binary_id, autogenerate: true}) do
      add :transaction_id, references(:transactions, type: :binary_id, on_delete: :delete_all)
      add :alert_type, :string
      add :severity, :string
      add :status, :string, default: "open"
      add :details, :map

      timestamps()
    end

    create index(:fraud_alerts, [:transaction_id])
    create index(:fraud_alerts, [:status])
  end
end
