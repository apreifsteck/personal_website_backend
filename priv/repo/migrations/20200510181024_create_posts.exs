defmodule APReifsteck.Repo.Migrations.CreatePosts do
  use Ecto.Migration

  def change do
    create table(:posts) do
      add(:user_id, references(:users, on_delete: :delete_all))
      add(:title, :string)
      add(:body, :string)
      add(:enable_comments, :boolean)
      timestamps()
    end

    create_index(:posts, [:user_id])
  end
end
