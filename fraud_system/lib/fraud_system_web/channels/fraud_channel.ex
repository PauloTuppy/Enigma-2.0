defmodule FraudSystemWeb.FraudChannel do
  use FraudSystemWeb, :channel

  @impl true
  def join("fraud:alerts", _payload, socket) do
    {:ok, socket}
  end

  # O React pode enviar mensagens para cá também se quiser
  @impl true
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end
end
