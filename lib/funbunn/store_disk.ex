defmodule Funbunn.StoreDisk do
  use GenServer
  @behaviour Funbunn.Store

  def start_link(_subreddit) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def subreddit(name) do
    lookup({:subreddit, name})
  end

  @impl true
  def insert_subreddit!(subreddit) do
    :dets.insert(table(), {{:subreddit, subreddit.name}, subreddit})
  end

  defp lookup(key) do
    case :dets.lookup(table(), key) do
      [{_key, result} | _] -> result
      [] -> nil
    end
  end

  @impl true
  def init(_) do
    with {:ok, _} <- table() |> :dets.open_file(type: :set) do
      :ok
    else
      {:error, reason} -> throw("Failed to create a file with reason: #{inspect(reason)}")
    end

    {:ok, nil}
  end

  defp table do
    Application.fetch_env!(:funbunn, :store_disk_filename)
  end
end
