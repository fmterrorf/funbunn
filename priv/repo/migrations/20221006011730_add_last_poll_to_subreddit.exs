defmodule Funbunn.Repo.Migrations.AddLastPollToSubreddit do
  use Ecto.Migration

  def change do
    alter table(:subreddits) do
      add     :last_poll_time,        :naive_datetime
      remove  :last_thread_name_seen
    end
  end
end
