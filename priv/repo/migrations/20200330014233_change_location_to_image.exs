defmodule APReifsteck.Repo.Migrations.ChangeLocationToImage do
  use Ecto.Migration

  def change do
    rename table(:images), :location, to: :image
  end
end
