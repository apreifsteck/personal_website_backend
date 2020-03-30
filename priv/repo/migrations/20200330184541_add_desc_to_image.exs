defmodule APReifsteck.Repo.Migrations.AddDescToImage do
  use Ecto.Migration

  def change do
    alter table("images") do
      add :description, :string
    end
  end
end
