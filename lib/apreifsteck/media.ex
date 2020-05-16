defmodule APReifsteck.Media do
  @moduledoc """
  The Media context.
  """

  import Ecto.Query, warn: false
  alias APReifsteck.Repo

  alias APReifsteck.Uploaders
  alias APReifsteck.Media.Image
  alias APReifsteck.Media.Post
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

  ############ POST FUNCTIONALITY ############
  def list_posts(user) do
    from(p in Post, where: p.user_id == ^user.id)
    |> Repo.all()
  end

  # TODO: sanatize the HTML in here before inserting
  def create_post(params, user) do
    %Post{}
    |> Post.changeset(params)
    |> Ecto.Changeset.put_assoc(:user, user)
    |> Repo.insert()
  end

  def get_post(id, user) do
    post =
      from(p in Post,
        where: p.id == ^id and p.user_id == ^user.id
      )
      |> Repo.one()

    case post do
      nil ->
        {:error, "must ask for post ID of a post from the given user"}

      _ ->
        post
    end
  end

  def get_post_history(id, user) do
  end

  def delete_post(id, user) do
  end

  defp get_root_post(post) do
  end

  def get_latest_edit(post) when is_struct(post) do
    cond do
      root = Repo.preload(post, [:root]).root ->
        # This is one of the children
        Repo.preload(root, [:children]).children

      root = Repo.preload(post, [:children]) ->
        # The root has children
        root.children

      true ->
        # This is the root, but it has no children
        post
    end
    |> Enum.max_by(
      fn child -> child.id end,
      fn -> post end
    )
  end

  def get_latest_edit(id) when is_integer(id) do
    Repo.get!(Post, id)
    |> get_latest_edit()
  end

  def update_post(id, user, attrs) do
    latest_post_id = get_latest_edit(id).id

    with %Post{} = post <- get_post(id, user),
         {:ok, %Post{}} = result when id == latest_post_id <-
           post
           |> Repo.preload([:user, :root])
           |> Post.create_edit(attrs)
           |> Repo.insert() do
      result
    else
      {:error, %Ecto.Changeset{} = changest} ->
        {:error, changest.errors}

      {:error, "must ask for post ID of a post from the given user"} = error ->
        error

      _ ->
        {:error, "may only edit the latest version of the post"}
    end
  end
end
