defmodule FraudSystem.Blockchain do
  use GenServer
  require Logger

  defstruct [:chain, :pending_evidence]

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %__MODULE__{chain: [genesis_block()], pending_evidence: []}, name: __MODULE__)
  end

  def add_evidence(data) do
    GenServer.call(__MODULE__, {:add_evidence, data})
  end

  def get_chain do
    GenServer.call(__MODULE__, :get_chain)
  end

  # Server Callbacks

  @impl true
  def init(state) do
    Logger.info("🔗 Enigma Blockchain started.")
    {:ok, state}
  end

  @impl true
  def handle_call({:add_evidence, data}, _from, state) do
    previous_block = List.last(state.chain)
    new_block = create_block(previous_block, data)
    
    new_chain = state.chain ++ [new_block]
    Logger.info("🧱 New Block Mined: #{inspect(new_block.hash)}")
    
    {:reply, {:ok, new_block}, %{state | chain: new_chain}}
  end

  @impl true
  def handle_call(:get_chain, _from, state) do
    {:reply, state.chain, state}
  end

  # Internal Functions

  defp genesis_block do
    %{
      index: 0,
      timestamp: DateTime.utc_now(),
      data: "GENESIS_BLOCK_ENIGMA_V2",
      previous_hash: "0",
      hash: hash_block(0, "0", "GENESIS_BLOCK_ENIGMA_V2")
    }
  end

  defp create_block(previous_block, data) do
    index = previous_block.index + 1
    timestamp = DateTime.utc_now()
    previous_hash = previous_block.hash
    hash = hash_block(index, previous_hash, data)

    %{
      index: index,
      timestamp: timestamp,
      data: data,
      previous_hash: previous_hash,
      hash: hash
    }
  end

  defp hash_block(index, previous_hash, data) do
    data_string = "#{index}#{previous_hash}#{inspect(data)}"
    :crypto.hash(:sha256, data_string) |> Base.encode16()
  end
end
