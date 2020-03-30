defmodule APReifsteck.Repo.Migrations.CreateImages do
  use Ecto.Migration

  def change do
    create table(:images) do
      add(:title, :string)
      add(:location, :string)
      add(:user_id, references(:users, on_delete: :delete_all))
      timestamps()
    end
  end
end
