defmodule Funbunn.ThreadPoller do
  use GenServer, restart: :temporary
  require Logger

  @poll_interval :timer.seconds(30)

  def start_link(subreddit) do
    GenServer.start_link(__MODULE__, subreddit)
  end

  @impl true
  def init(subreddit) do
    send(self(), :poll)
    {:ok, {subreddit, []}}
  end

  @impl true
  def handle_info(:poll, {subreddit, ids = []}) do
    # TODO: Fetch from store
    new_ids = fetch_entries(subreddit, ids)
    Process.send_after(self(), :poll, @poll_interval)
    {:noreply, {subreddit, new_ids}}
  end

  @impl true
  def handle_info(:poll, {subreddit, ids}) do
    new_ids = fetch_entries(subreddit, ids)
    Process.send_after(self(), :poll, @poll_interval)
    {:noreply, {subreddit, new_ids}}
  end

  defp fetch_entries(subreddit, ids) do
    with {:ok, entries} <- Funbunn.Api.fetch_new_entries(subreddit) do
      new_ids = Enum.map(entries, fn item -> item.id end)

      entry_ids_to_send =
        MapSet.new(new_ids)
        |> MapSet.difference(MapSet.new(ids))
        |> MapSet.to_list()

      Enum.filter(entries, fn item -> item.id in entry_ids_to_send end)
      |> maybe_send_to_discord()

      new_ids
    else
      {:error, reason} ->
        Logger.error("fetch_entries returne with #{reason}")
        ids
    end
  end

  defp maybe_send_to_discord(items = [_ | _]) do
    Funbunn.Api.send_to_discord(items)
  end

  defp maybe_send_to_discord(_items) do
    Logger.debug("No new items found. Skipping")
  end
end
