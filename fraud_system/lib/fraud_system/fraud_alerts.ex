defmodule FraudSystem.FraudAlerts do
  @moduledoc """
  The FraudAlerts context.
  """

  import Ecto.Query, warn: false
  alias FraudSystem.Repo
  alias FraudSystem.FraudAlerts.FraudAlert

  def list_fraud_alerts do
    Repo.all(FraudAlert)
  end

  def get_fraud_alert!(id), do: Repo.get!(FraudAlert, id)

  def create_fraud_alert(attrs \\ %{}) do
    %FraudAlert{}
    |> FraudAlert.changeset(attrs)
    |> Repo.insert()
  end

  def update_fraud_alert(%FraudAlert{} = fraud_alert, attrs) do
    fraud_alert
    |> FraudAlert.changeset(attrs)
    |> Repo.update()
  end

  def delete_fraud_alert(%FraudAlert{} = fraud_alert) do
    Repo.delete(fraud_alert)
  end

  def change_fraud_alert(%FraudAlert{} = fraud_alert, attrs \\ %{}) do
    FraudAlert.changeset(fraud_alert, attrs)
  end
end
