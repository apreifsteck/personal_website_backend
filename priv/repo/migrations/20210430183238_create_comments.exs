defmodule APReifsteck.Repo.Migrations.CreateComments do
  use Ecto.Migration

  def change do
    create table(:comments) do
      add(:author_id, references(:users, on_delete: :delete_all), null: false)
      add(:body, :string, null: false)
      add(:post_id, references(:posts, on_delete: :delete_all), null: false)
      add(:parent_comment_id, references(:comments))
      add(:edited, :boolean, default: false)
      timestamps()
    end
  end
end
