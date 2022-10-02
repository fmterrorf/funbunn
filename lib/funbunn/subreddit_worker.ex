defmodule Funbunn.SubredditWorker do
  use GenServer, restart: :temporary
  require Logger

  @poll_interval :timer.minutes(5)

  def start_link(subreddit) do
    GenServer.start_link(__MODULE__, subreddit)
  end

  @impl true
  def init(subreddit) do
    Logger.info("Starting #{__MODULE__} for #{subreddit}")
    send(self(), :poll)
    {:ok, {subreddit, ids_from_store(subreddit)}}
  end

  @impl true
  def handle_info(:poll, {subreddit, ids} = state) do
    state =
      with {:ok, entries} <- Funbunn.Api.fetch_new_entries(subreddit) do
        latest_ids = Enum.map(entries, fn item -> item.id end)
        ids_to_send = extract_ids_for_sending(latest_ids, ids)

        if ids_to_send != [] do
          Enum.filter(entries, fn item -> item.id in ids_to_send end)
          |> maybe_send_to_discord(subreddit, ids)

          Funbunn.Store.insert_subreddit!(%{
            name: subreddit,
            thread_ids: latest_ids
          })
        else
          Logger.info("No new posts found for subreddit: #{subreddit}")
        end

        {subreddit, latest_ids}
      else
        _ ->
          Logger.warn("Fetching new entries failed. Skipping...")
          state
      end

    Process.send_after(self(), :poll, @poll_interval)
    {:noreply, state}
  end

  # PUBSUB

  def subscribe(subreddit) do
    Phoenix.PubSub.subscribe(
      Funbunn.PubSub,
      topic(subreddit)
    )
  end

  def publish(subreddit, message) do
    Phoenix.PubSub.broadcast(
      Funbunn.PubSub,
      topic(subreddit),
      message
    )
  end

  def topic(subreddit) do
    "subreddit:#{subreddit}"
  end

  # Helpers

  defp extract_ids_for_sending(latest_ids, old_ids) do
    MapSet.new(latest_ids)
    |> MapSet.difference(MapSet.new(old_ids))
    |> MapSet.to_list()
  end

  defp ids_from_store(subreddit) do
    if sub = Funbunn.Store.subreddit(subreddit) do
      sub.thread_ids
    else
      []
    end
  end

  defp maybe_send_to_discord(items = [_ | _], subreddit, _ids = [_ | _]) do
    messages = Funbunn.DiscordBody.new(items)
    Logger.debug("Sending #{length(messages)} to SubredditWorker")

    Enum.each(messages, fn messages ->
      {_, id} = key = {:messages, Ecto.UUID.generate()}
      Funbunn.Cache.insert(key, messages)
      Funbunn.SubredditWorker.publish(subreddit, {:deliver, id})
    end)
  end

  # defp maybe_send_to_discord(_items, _subreddit, _ids = []) do
  #   Logger.debug("Initial run of #{__MODULE__}. Skip sending messages to discord")
  # end

  defp maybe_send_to_discord(_items, _subreddit, _ids) do
    Logger.debug("No new items found. Skipping")
  end
end
