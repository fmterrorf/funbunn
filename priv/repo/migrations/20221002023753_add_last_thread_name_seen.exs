defmodule Funbunn.Repo.Migrations.AddLastThreadNameSeen do
  use Ecto.Migration

  def change do
    alter table(:subreddits) do
      add     :last_thread_name_seen, :text
      remove  :thread_ids
    end
  end
end
