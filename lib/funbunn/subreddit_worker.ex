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
  def handle_info(:poll, {subreddit, _last_thread_name} = state) do
    state =
      with {:ok, thread_name} <- last_thread_name(state) do
        {subreddit, thread_name}
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

  def last_thread_name({subreddit, last_thread_name} = _state) do
    Logger.info("Try fetching for new entries for sub: #{subreddit}")

    with {:ok, entries} = Funbunn.Api.fetch_new_entries(subreddit, before: last_thread_name) do
      case entries do
        entries = [%{name: thread_name} | _] ->
          send_to_discord(entries, subreddit)

          Funbunn.Store.insert_subreddit!(%{
            name: subreddit,
            last_thread_name_seen: thread_name
          })

          {:ok, thread_name}

        [] ->
          Logger.info("Do a retry fetching for new entries for sub: #{subreddit}")

          with {:ok, [%{name: thread_name} | _] = entries} <-
                 Funbunn.Api.fetch_new_entries(subreddit) do
            Enum.take_while(entries, fn item -> item.name != last_thread_name end)
            |> send_to_discord(subreddit)

            Funbunn.Store.insert_subreddit!(%{
              name: subreddit,
              last_thread_name_seen: thread_name
            })

            {:ok, thread_name}
          end
      end
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

  defp send_to_discord(_items, _subreddit), do: :ok
end
