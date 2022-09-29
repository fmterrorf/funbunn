defmodule Funbunn.WebhookDeliveryWorker do
  use GenServer
  require Logger

  def start_link(config) do
    GenServer.start_link(__MODULE__, config)
  end

  def init(config) do
    Funbunn.SubredditWorker.subscribe(config.subreddit)
    {:ok, config}
  end

  def handle_info({:deliver, key}, state) do
    attachment = Funbunn.Cache.get({:messages, key})
    Logger.debug("Sending #{length(attachment)} attachments for subreddit #{state.subreddit}")

    Req.post!(
      state.webhook,
      json: attachment
    )

    {:noreply, state}
  end
end
