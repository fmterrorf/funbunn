defmodule Funbunn.StorePostgres.Subreddits do
  use Ecto.Schema

  schema "subreddits" do
    field(:name, :string)
    field(:last_thread_name_seen, :string)

    timestamps()
  end
end

defmodule Funbunn.StorePostgres do
  alias Funbunn.Repo

  @behaviour Funbunn.Store

  @impl true
  def subreddit(subreddit_name) do
    if sub = Repo.get_by(Funbunn.StorePostgres.Subreddits, name: subreddit_name) do
      %{name: sub.name, last_thread_name_seen: sub.last_thread_name_seen}
    end
  end

  @impl true
  def insert_subreddit!(subreddit) do
    %Funbunn.StorePostgres.Subreddits{
      name: subreddit.name,
      last_thread_name_seen: subreddit.last_thread_name_seen
    }
    |> Repo.insert!(
      on_conflict: [set: [last_thread_name_seen: subreddit.last_thread_name_seen]],
      conflict_target: :name
    )
  end
end
