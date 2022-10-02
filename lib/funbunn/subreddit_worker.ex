defmodule Funbunn.SubredditWorker do
  use GenServer, restart: :temporary
  require Logger

  @poll_interval :timer.minutes(10)

  def start_link(subreddit) do
    GenServer.start_link(__MODULE__, subreddit)
  end

  @impl true
  def init(subreddit) do
    Logger.info("Starting #{__MODULE__} for #{subreddit}")
    send(self(), :poll)
    {:ok, {subreddit, thread_name_from_store(subreddit)}}
  end

  @impl true
  def handle_info(:poll, {subreddit, last_thread_name} = state) do
    state =
      with {:ok, entries = [%{name: latest_thread_name} | _]} <-
             Funbunn.Api.fetch_new_entries(subreddit, last_thread_name) do
        send_to_discord(entries, subreddit)

        Funbunn.Store.insert_subreddit!(%{
          name: subreddit,
          last_thread_name_seen: latest_thread_name
        })

        {subreddit, latest_thread_name}
      else
        {:error, reason} ->
          Logger.error("Fetching new entries failed. Reason: #{inspect(reason)}")

        _ ->
          Logger.info("No new entries found for subreddit: #{subreddit}. Skipping...")
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

  defp thread_name_from_store(subreddit) do
    if sub = Funbunn.Store.subreddit(subreddit) do
      sub.last_thread_name_seen
    end
  end

  defp send_to_discord(items = [_ | _], subreddit) do
    messages = Funbunn.DiscordBody.new(items)
    Logger.debug("Sending #{length(messages)} to #{subreddit} SubredditWorker")

    Enum.each(messages, fn messages ->
      {_, id} = key = {:messages, Ecto.UUID.generate()}
      Funbunn.Cache.insert(key, messages)
      Funbunn.SubredditWorker.publish(subreddit, {:deliver, id})
    end)
  end
end
