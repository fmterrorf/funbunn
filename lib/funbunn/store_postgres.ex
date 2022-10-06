defmodule Funbunn.StorePostgres.Subreddits do
  use Ecto.Schema

  schema "subreddits" do
    field(:name, :string)
    field(:last_poll_time, :naive_datetime)

    timestamps()
  end
end

defmodule Funbunn.StorePostgres do
  alias Funbunn.Repo

  @behaviour Funbunn.Store

  @impl true
  def subreddit(subreddit_name) do
    if sub = Repo.get_by(Funbunn.StorePostgres.Subreddits, name: subreddit_name) do
      %{name: sub.name, last_poll_time: sub.last_poll_time}
    end
  end

  @impl true
  def insert_subreddit!(subreddit) do
    %Funbunn.StorePostgres.Subreddits{
      name: subreddit.name,
      last_poll_time: subreddit.last_poll_time
    }
    |> Repo.insert!(
      on_conflict: [set: [last_poll_time: subreddit.last_poll_time]],
      conflict_target: :name
    )
  end
end
