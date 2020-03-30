defmodule APReifsteck.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add(:name, :string, null: false)
      add(:uname, :string, null: false)
      add(:email, :string)
      add(:password_hash, :string)

      timestamps()
    end
  end
end
