defmodule Funbunn.StorePostgres.Subreddits do
  use Ecto.Schema

  schema "subreddits" do
    field(:name, :string)
    field(:thread_ids, {:array, :string})

    timestamps()
  end
end

defmodule Funbunn.StorePostgres do
  alias Funbunn.Repo

  @behaviour Funbunn.Store

  @impl true
  def subreddit(subreddit_name) do
    if sub = Repo.get_by(Funbunn.StorePostgres.Subreddits, name: subreddit_name) do
      %{name: sub.name, thread_ids: sub.thread_ids}
    end
  end

  @impl true
  def insert_subreddit!(subreddit) do
    %Funbunn.StorePostgres.Subreddits{
      name: subreddit.name,
      thread_ids: subreddit.thread_ids
    }
    |> Repo.insert!(
      on_conflict: [set: [thread_ids: subreddit.thread_ids]],
      conflict_target: :name
    )
  end
end
