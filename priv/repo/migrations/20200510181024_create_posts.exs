defmodule APReifsteck.Repo.Migrations.CreatePosts do
  use Ecto.Migration

  def change do
    create table(:posts) do
      add(:user_id, references(:users, on_delete: :delete_all))
      add(:title, :string, null: false)
      add(:body, :string, null: false)
      add(:root_id, references(:posts, on_delete: :delete_all))
      add(:enable_comments, :boolean, default: true)
      timestamps()
    end

    create index(:posts, [:user_id])
    create index(:posts, [:root_id])
  end
end
