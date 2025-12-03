defmodule FraudSystemWeb.HealthController do
  use FraudSystemWeb, :controller

  def index(conn, _params) do
    json(conn, %{status: "ok", service: "fraud_system"})
  end
end
