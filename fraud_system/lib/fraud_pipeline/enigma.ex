defmodule FraudPipeline.Enigma do
  @moduledoc """
  O núcleo de inteligência que 'quebra' o padrão das bets.
  """

  # Pattern 1: Bloqueio Artificial de Saque (Erro específico + Valor alto)
  def analyze(%{"error" => "WITHDRAW_BLOCKED", "amount" => amount} = _tx) 
      when amount > 1000 do
    {:fraud, :artificial_block, 0.95}
  end

  # Pattern 2: Ciclo de Lavagem (Depósito seguido de Saque rápido)
  # (Simplificado para stateless, idealmente usaria banco/janela de tempo)
  def analyze(%{"type" => "WITHDRAW", "user_risk_score" => score}) 
      when score > 80 do
    {:fraud, :money_laundering_risk, 0.85}
  end

  # Pattern 3: Velocity Spike (Muitas tentativas em milissegundos)
  # Detectado via cabeçalho ou metadados do Kafka
  def analyze(%{"velocity_flag" => true}) do
    {:fraud, :velocity_attack, 0.99}
  end

  # Caso padrão: Parece legítimo
  def analyze(_tx), do: {:ok, :clean, 0.0}
end
