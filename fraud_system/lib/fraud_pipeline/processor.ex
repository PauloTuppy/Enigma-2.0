defmodule FraudPipeline.Processor do
  use Broadway

  alias Broadway.Message
  require Logger

  def start_link(_opts) do
    kafka_config = Application.get_env(:fraud_system, :kafka)
    
    producer_config = [
      hosts: kafka_config[:hosts],
      group_id: kafka_config[:group_id],
      topics: kafka_config[:topics]
    ]

    # Add SASL/SSL config if username is present
    producer_config = 
      if kafka_config[:sasl_username] do
        producer_config ++ [
          client_config: [
            ssl: true,
            sasl: {:plain, kafka_config[:sasl_username], kafka_config[:sasl_password]}
          ]
        ]
      else
        producer_config
      end

    Broadway.start_link(__MODULE__,
      name: __MODULE__,
      producer: [
        module: {BroadwayKafka.Producer, producer_config},
        concurrency: 2
      ],
      processors: [
        default: [concurrency: 50] # 50 processos analisando em paralelo
      ],
      batchers: [
        default: [batch_size: 100, batch_timeout: 200]
      ]
    )
  end

  @impl true
  def handle_message(_, message, _) do
    # Decodifica JSON
    data = Jason.decode!(message.data)

    # 1. Análise Local (Enigma)
    {local_status, local_reason, local_score} = FraudPipeline.Enigma.analyze(data)

    # 2. Análise Remota (Vertex AI)
    # Executa em paralelo ou sequencial dependendo da latência desejada.
    # Aqui faremos sequencial para simplificar.
    vertex_score = 
      case FraudPipeline.VertexClient.score_transaction(data) do
        {:ok, score} -> score
        _ -> 0.0 # Fallback seguro
      end

    # 3. Combinar Scores (Lógica simples de média ponderada ou max)
    final_fraud_score = max(local_score, vertex_score)
    
    {final_status, final_reason} = 
      cond do
        final_fraud_score > 0.8 -> {:fraud, local_reason || "Vertex AI High Risk"}
        final_fraud_score > 0.5 -> {:review, "Medium Risk"}
        true -> {:ok, "Clean"}
      end

    # Enriquece a mensagem
    result = Map.merge(data, %{
      "fraud_status" => Atom.to_string(final_status),
      "fraud_reason" => final_reason,
      "fraud_score" => final_fraud_score,
      "processed_at" => DateTime.utc_now()
    })

    message
    |> Message.update_data(fn _ -> result end)
    |> Message.put_batcher(:default)
  end

  @impl true
  def handle_batch(_, messages, _, _) do
    # 1. Persistir Transações no Banco
    transactions = Enum.map(messages, & &1.data)
    
    # Idealmente usar Repo.insert_all, mas para garantir validações vamos de um em um ou chunks
    # Para simplificar e garantir que o Contexto rode:
    Enum.each(transactions, fn tx_data ->
      # Mapear campos do JSON para o Schema
      attrs = %{
        transaction_id: tx_data["transaction_id"],
        user_id: tx_data["user_id"],
        amount_brl: tx_data["amount_brl"],
        fraud_score: tx_data["fraud_score"],
        fraud_status: tx_data["fraud_status"],
        fraud_reason: tx_data["fraud_reason"],
        processed_at: tx_data["processed_at"]
        # Adicionar outros campos conforme mapeamento...
      }
      
      case FraudSystem.Transactions.create_transaction(attrs) do
        {:ok, tx} -> 
          # Se for fraude, criar alerta
          if tx.fraud_status == "fraud" do
            FraudSystem.FraudAlerts.create_fraud_alert(%{
              transaction_id: tx.id,
              alert_type: "fraud_detected",
              severity: "high",
              status: "open",
              details: tx_data
            })
          end
        error ->
          Logger.error("Failed to persist transaction: #{inspect(error)}")
      end
    end)

    # 2. Enviar para o Frontend via WebSocket (Apenas Fraudes ou Todas?)
    # Vamos enviar as fraudes para o canal de alertas
    frauds = Enum.filter(transactions, fn tx -> tx["fraud_status"] == "fraud" end)

    if length(frauds) > 0 do
      FraudSystemWeb.Endpoint.broadcast("fraud:alerts", "new_batch", %{frauds: frauds})
      Logger.warning("🚨 Detected #{length(frauds)} frauds in batch!")
    end

    messages
  end
end
