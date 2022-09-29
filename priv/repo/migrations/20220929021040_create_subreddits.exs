defmodule Funbunn.Repo.Migrations.CreateSubreddits do
  use Ecto.Migration

  def change do
    create table(:subreddits) do
      add(:name, :string)
      add(:thread_ids, {:array, :string})

      timestamps()
    end

    create(index("subreddits", [:name], unique: true))
  end
end
