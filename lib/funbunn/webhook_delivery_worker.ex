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

    res = Req.post!(
      state.webhook,
      json: attachment
    )

    if res.status >= 400 do
      Logger.error("WebhookDeliveryWorker encountered status: #{res.status}, reason: #{inspect(res.body)}")
    end

    {:noreply, state}
  end
end
