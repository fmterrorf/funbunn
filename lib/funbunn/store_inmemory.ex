defmodule Funbunn.StoreInmemory do
  use GenServer
  @behaviour Funbunn.Store

  def start_link(_arg) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def insert_subreddit!(subreddit) do
    GenServer.cast(__MODULE__, {:insert, subreddit})
  end

  @impl true
  def subreddit(name) do
    GenServer.call(__MODULE__, {:get_subreddit, name})
  end

  @impl true
  def init(_init_arg) do
    {:ok, %{}}
  end

  @impl true
  def handle_cast({:insert, subreddit}, state) do
    {:noreply, Map.put(state, subreddit.name, subreddit)}
  end

  @impl true
  def handle_call({:get_subreddit, name}, _from, state) do
    {:reply, Map.get(state, name), state}
  end
end
