defmodule Funbunn.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    route_config =
      Application.get_env(:funbunn, :route_config_string) |> Funbunn.RoutingConfig.parse!()

    children =
      [
        {Phoenix.PubSub, name: Funbunn.PubSub},
        {ConCache,
         [
           name: :funbunn_cache,
           ttl_check_interval: :timer.minutes(20),
           global_ttl: :timer.hours(2)
         ]},
        Funbunn.Store.repo()
      ]
      |> thread_poller_children(route_config)
      |> message_delivery_children(route_config)

    opts = [strategy: :one_for_one, name: Funbunn.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp message_delivery_children(children, route_configs) do
    new_children =
      Enum.map(route_configs, fn config ->
        Supervisor.child_spec(
          {Funbunn.WebhookDeliveryWorker, config},
          id: {Funbunn.WebhookDeliveryWorker, config.subreddit}
        )
      end)

    children ++ new_children
  end

  defp thread_poller_children(children, route_configs) do
    new_child =
      Enum.map(route_configs, fn item -> item.subreddit end)
      |> Enum.uniq()
      |> Enum.map(fn subreddit ->
        Supervisor.child_spec(
          {Funbunn.SubredditWorker, subreddit},
          id: {Funbunn.SubredditWorker, subreddit}
        )
      end)

    children ++ new_child
  end
end
