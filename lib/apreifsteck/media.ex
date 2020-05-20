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
  # I don't want the edits to show up on the root level, but I do want them listed as children

  def list_posts() do
    from(p in Post,
      where: is_nil(p.root_id),
      left_join: edits in assoc(p, :children),
      # ascending by default
      order_by: edits.id,
      preload: [children: {edits, []}]
    )
    |> Repo.all()
  end

  # REFACTOR
  def list_posts(user) do
    from(p in Post,
      where: p.user_id == ^user.id and is_nil(p.root_id),
      preload: [children: [:children]]
    )
    |> Repo.all()
  end

  def create_post(params, user) do
    %Post{}
    |> Post.changeset(params)
    |> Ecto.Changeset.put_assoc(:user, user)
    |> Repo.insert()
  end

  # TODO: might want to put this authentication into another function that
  # I somehow pipe the other functions through? I don't want to get hung up on a ton
  # of refactoring though.
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

  def get_post(id) do
    case post = Repo.get(Post, id) do
      nil -> {:error, :not_found}
      _ -> {:ok, post}
    end
  end

  def delete_post(id, user) do
    with %Post{root_id: root_id} = post <- get_post(id, user),
         {:ok, %Post{}} = result when is_nil(root_id) <- Repo.delete(post) do
      result
    else
      {:error, %Ecto.Changeset{} = changest} ->
        {:error, changest.errors}

      {:error, "must ask for post ID of a post from the given user"} = error ->
        error

      _ ->
        {:error, "you can only delete posts from the root post"}
    end
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

  def get_latest_edit(id) do
    Repo.get!(Post, id)
    |> get_latest_edit()
  end

  def update_post(id, user, attrs) when is_binary(id) do
    update_post(String.to_integer(id), user, attrs)
  end

  def update_post(id, user, attrs) when is_integer(id) do
    latest_post_id = get_latest_edit(id).id

    with %Post{} = post when id == latest_post_id <- get_post(id, user),
         result = {:ok, %Post{}} <-
           post
           |> Repo.preload([:user, :root])
           |> Post.create_edit(attrs)
           |> Repo.insert() do
      result
    else
      {:error, %Ecto.Changeset{} = changest} ->
        {:error, changest}

      {:error, _} = error ->
        error

      _ ->
        {:error, "may only edit the latest version of the post"}
    end
  end
end
