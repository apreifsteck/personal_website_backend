defmodule APReifsteck.Media.Image do
  use Ecto.Schema
  use Arc.Ecto.Schema
  import Ecto.Changeset

  schema "images" do
    field :title, :string
    field :image, APReifsteck.Uploaders.Image.Type
    belongs_to :user, APReifsteck.Accounts.User
    timestamps()
  end

  @doc false
  def changeset(image, attrs) do
    IO.inspect(attrs)

    image
    |> cast(attrs, [:title])
    |> cast_attachments(attrs, [:image])
    |> validate_required([:title, :image])
    |> assoc_constraint(:user)
  end
end
