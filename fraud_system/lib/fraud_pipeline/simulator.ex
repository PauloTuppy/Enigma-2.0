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
    
    # In a real scenario, we would use a Kafka Producer here (e.g., Brod or Kaffe)
    # For this PoC, we will simulate the "Input" by sending directly to the Processor
    # OR we can just log it if we don't have a running Kafka producer set up in code yet.
    # Ideally, we produce to Kafka.
    
    # For simplicity in this "Fortress" setup without a full Kafka Producer config:
    # We will just Log it for now, assuming the user will hook up the Producer later
    # OR we can try to use a simple producer if we had one.
    
    # Let's simulate the "Arrival" of the message by calling the Processor logic directly 
    # if we wanted to test without Kafka, but the plan says Kafka.
    
    # TODO: Implement actual Kafka Production. 
    # For now, we will just print to console to show activity.
    Logger.info("🎲 Generated Bet: #{inspect(bet)}")

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
