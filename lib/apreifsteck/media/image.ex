defmodule APReifseck.Media.Image do
  use Ecto.Schema
  use Arc.Ecto.Schema
  import Ecto.Changeset

  schema "images" do
    field :title, :string
    field :image, APReifsteck.Image.Type
    timestamps()
  end

  @doc false
  def changeset(image, attrs) do
    image
    |> cast(attrs, [:title])
    |> cast_attachments(attrs, [:image])
    |> validate_required([[:title, :image]])
  end
end
