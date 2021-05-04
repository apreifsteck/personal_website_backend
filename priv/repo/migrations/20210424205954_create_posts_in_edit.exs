defmodule APReifsteck.Repo.Migrations.CreatePostsInEdit do
  use Ecto.Migration

  def change do
    create table(:posts_in_edit) do
      add(:parent_id, references(:posts, on_delete: :delete_all), null: false)
      timestamps()
    end
  end
end
