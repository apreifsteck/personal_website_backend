defmodule APReifsteck.Repo.Migrations.CreateImages do
  use Ecto.Migration

  def change do
    create table(:images) do
      add(:title, :string)
      add(:description, :string)
      add(:filename, :string, null: false)
      add(:user_id, references(:users, on_delete: :delete_all), null: false)
      timestamps()
    end

    create unique_index(:images, [:filename, :user_id])
  end
end
