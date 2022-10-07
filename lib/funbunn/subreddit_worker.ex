defmodule Funbunn.SubredditWorker do
  use GenServer, restart: :temporary
  require Logger

  @poll_interval :timer.minutes(1)

  def start_link(subreddit) do
    GenServer.start_link(__MODULE__, subreddit)
  end

  @impl true
  def init(subreddit) do
    Logger.info("Starting #{__MODULE__} for #{subreddit}")
    send(self(), :poll)
    {:ok, {subreddit, DateTime.utc_now()}}
  end

  @impl true
  def handle_info(:poll, {subreddit, _} = state) do
    new_state =
      with {:ok, poll_time} <- do_poll(state) do
        {subreddit, poll_time}
      else
        _ -> state
      end

    Process.send_after(self(), :poll, @poll_interval)
    {:noreply, new_state}
  end

  def do_poll({subreddit, last_poll_time}) do
    Logger.info(
      "Try fetching for new entries for sub: #{subreddit}, last_poll_time: #{inspect(last_poll_time)}"
    )

    with {:ok, entries} <- Funbunn.Api.fetch_new_entries(subreddit),
         {:ok, new_entries} <- filter_new_posts(entries, last_poll_time) do
      send_to_discord(new_entries, subreddit)
      {:ok, DateTime.utc_now()}
    end
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

  defp filter_new_posts(entries, cutoff) do
    case Enum.take_while(entries, fn item ->
           NaiveDateTime.compare(item.created_at, cutoff) == :gt
         end) do
      [_ | _] = items -> {:ok, items}
      _ -> {:error, :no_new_items}
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
