defmodule FraudSystem.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Inicia o Banco de Dados
      FraudSystem.Repo,
      # Inicia a Telemetria
      FraudSystemWeb.Telemetry,
      # Inicia o PubSub (para Channels)
      {Phoenix.PubSub, name: FraudSystem.PubSub},
      # Inicia o Endpoint Web (API)
      FraudSystemWeb.Endpoint,
      # Inicia o Processador Kafka (Broadway)
      FraudPipeline.Processor,
      # Inicia o Simulador de Apostas
      FraudPipeline.Simulator,
      # Inicia a Blockchain Enigma
      FraudSystem.Blockchain
    ]

    opts = [strategy: :one_for_one, name: FraudSystem.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
