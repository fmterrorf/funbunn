defmodule Funbunn.Store do
  @type subreddit :: %{
          name: binary(),
          last_thread_name_seen: binary()
        }

  @callback subreddit(String.t()) :: subreddit() | nil
  @callback insert_subreddit!(subreddit()) :: :ok

  def subreddit(subreddit_name), do: store_impl() |> subreddit(subreddit_name)
  def subreddit(module, subreddit_name), do: module.subreddit(subreddit_name)

  def insert_subreddit!(subreddit), do: store_impl() |> insert_subreddit!(subreddit)
  def insert_subreddit!(module, subreddit), do: module.insert_subreddit!(subreddit)

  def store_impl, do: Application.fetch_env!(:funbunn, :store)

  def repo do
    case store_impl() do
      Funbunn.StorePostgres -> Funbunn.Repo
      repo -> repo
    end
  end
end
