defmodule APReifsteck.Media do
  @moduledoc """
  The Media context.
  """

  import Ecto.Query, warn: false
  alias APReifsteck.Repo

  alias APReifsteck.Uploaders
  alias APReifsteck.Media.Image
  alias APReifsteck.Accounts

  @doc """
  Returns the list of images.

  ## Examples

      iex> list_images()
      [%Image{}, ...]

  """
  def list_images do
    Repo.all(Image)
  end

  def list_user_images(uid) do
    from(v in Image, where: v.user_id == ^uid)
    |> Repo.all()
  end

  @doc """
  Gets a single image.

  Raises `Ecto.NoResultsError` if the Image does not exist.

  ## Examples

      iex> get_image!(123)
      %Image{}

      iex> get_image!(456)
      ** (Ecto.NoResultsError)

  """
  def get_image!(id), do: Repo.get!(Image, id)

  @doc """
  Creates a image.

  ## Examples

      iex> create_image(%{field: value})
      {:ok, %Image{}}

      iex> create_image(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_image(%Accounts.User{} = user, attrs \\ %{}) do
    %Image{}
    |> Image.changeset(user, attrs)
    |> Ecto.Changeset.put_assoc(:user, user)
    |> Repo.insert()
  end

  # TODO error handling if there is no matching keys and stuff

  @doc """
  Updates a image.

  ## Examples

      iex> update_image(image, %{field: new_value})
      {:ok, %Image{}}

      iex> update_image(image, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_image(%Image{} = image, attrs) do
    image
    |> Image.update_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a image.

  ## Examples

      iex> delete_image(image)
      {:ok, %Image{}}

      iex> delete_image(image)
      {:error, %Ecto.Changeset{}}

  """
  def delete_image(%Accounts.User{} = user, %Image{} = image) do
    spawn(fn -> Uploaders.Image.delete({image.filename, user}) end)
    Repo.delete(image)
  end
end
