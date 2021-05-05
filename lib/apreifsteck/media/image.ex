defmodule APReifsteck.Media.Image do
  use Ecto.Schema
  import Ecto.Changeset
  alias APReifsteck.Uploaders

  schema "images" do
    field :title, :string
    field :description, :string
    field :filename, :string
    belongs_to :user, APReifsteck.Accounts.User
    timestamps()
  end

  @doc false
  def changeset(image, _, attrs = %{"image" => nil}) do
    image
    |> change()
    |> add_error(:missing_image, "Must have an image object to create an image")
  end

  def changeset(image, user, attrs) do
    attrs =
      attrs
      |> restructure_attrs()
      |> store_image(user)

    image
    |> cast(attrs, [:title, :description, :filename])
    |> validate_required([:filename])
    |> assoc_constraint(:user)
    |> unique_constraint(:filename)
  end

  @doc """
  The changeset operation used for updating an image. This is so the filename or associated user can't be changed.
  """
  def update_changeset(image, attrs) do
    attrs = restructure_attrs(attrs)

    case attrs do
      %{image: _} ->
        Ecto.Changeset.change(image)
        |> add_error(:image, "Cannot modify image object after upload",
          fix: "delete image and upload the one you want"
        )

      _ ->
        image
        |> cast(attrs, [:title, :description])
    end
  end

  defp restructure_attrs(%{} = attrs) do
    Map.take(attrs, ["image", "description", "title"])
    |> Enum.map(fn {k, v} -> {String.to_existing_atom(k), v} end)
    |> Enum.into(%{})
  end

  defp store_image(%{image: image} = attrs, user) do
    {:ok, _} = Uploaders.Image.store({image, user})
    filename = Uploaders.Image.filename(image, user)

    attrs
    |> Map.put(:filename, filename)
    |> Map.pop!(:image)
    |> elem(1)
  end

  # if there is no image key, just pass the attrs through, it'll ultimately give you back a changeset error
  defp store_image(%{} = attrs, _user) do
    attrs
  end
end
