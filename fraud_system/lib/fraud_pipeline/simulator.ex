defmodule FraudPipeline.Simulator do
  use GenServer
  require Logger

  @topic "bets-transactions"
  @interval 100 # 100ms = 10 bets/sec per process

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def init(state) do
    # Start the simulation loop
    schedule_next_bet()
    {:ok, state}
  end

  @impl true
  def handle_info(:generate_bet, state) do
    bet = generate_random_bet()
    
    # Run through Enigma analysis
    {status, reason, score} = FraudPipeline.Enigma.analyze(bet)
    
    # Enrich the transaction with fraud analysis
    processed_bet = Map.merge(bet, %{
      "fraud_status" => Atom.to_string(status),
      "fraud_reason" => Atom.to_string(reason),
      "fraud_score" => score,
      "processed_at" => DateTime.utc_now() |> DateTime.to_iso8601()
    })
    
    # Broadcast ALL transactions to frontend for real-time display
    FraudSystemWeb.Endpoint.broadcast("fraud:alerts", "new_batch", %{frauds: [processed_bet]})
    
    # Log fraud detections
    if status == :fraud do
      Logger.warning("🚨 FRAUD DETECTED: #{inspect(processed_bet)}")
    else
      Logger.debug("✅ Clean transaction: #{bet["transaction_id"]}")
    end

    schedule_next_bet()
    {:noreply, state}
  end

  defp schedule_next_bet do
    Process.send_after(self(), :generate_bet, @interval)
  end

  defp generate_random_bet do
    %{
      "transaction_id" => UUID.uuid4(),
      "timestamp" => DateTime.utc_now() |> DateTime.to_unix(),
      "amount" => :rand.uniform(5000),
      "user_id" => "user_#{:rand.uniform(1000)}",
      "bet_site" => Enum.random(["betfake.com", "winbig.br", "lucky.net"]),
      "error" => Enum.random([nil, nil, nil, "WITHDRAW_BLOCKED"]), # 25% chance of error
      "velocity_flag" => :rand.uniform(100) > 95 # 5% chance of velocity flag
    }
  end
end
