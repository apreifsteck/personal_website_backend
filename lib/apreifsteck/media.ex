defmodule APReifsteck.Media do
  @moduledoc """
  The Media context.
  """

  import Ecto.Query, warn: false
  alias APReifsteck.Repo

  alias APReifsteck.Uploaders
  alias APReifsteck.{Media, Media.Image, Media.Post}
  alias APReifsteck.Accounts.User

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
  def create_image(%User{} = user, attrs \\ %{}) do
    user
    |> Ecto.build_assoc(:images)
    |> Image.changeset(user, attrs)
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
  def delete_image(%User{} = user, %Image{} = image) do
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

  def get_post!(id), do: Repo.get!(Post, id)

  def get_latest_edit(%Post{} = post) do
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

  def get_root_post(%Post{} = post) do
    post = Repo.preload(post, [:root])

    case post.root do
      # If the post has no root, it is at the top of the tree/list
      nil ->
        post

      # otherwise we want to recurse to the previous post in the edit list 
      prev_post ->
        get_root_post(prev_post)
    end
  end

  def get_root_post(id) do
    Repo.get(Post, id)
    |> get_root_post()
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

  ######### POSTS IN EDIT ##########
  alias APReifsteck.Media.PostInEdit

  @doc """
  Returns the list of posts_in_edit.

  ## Examples

      iex> list_posts_in_edit()
      [%PostInEdit{}, ...]

  """
  def list_posts_in_edit do
    Repo.all(PostInEdit)
  end

  @doc """
  Gets a single post_in_edit.

  Raises `Ecto.NoResultsError` if the Post in edit does not exist.

  ## Examples

      iex> get_post_in_edit!(123)
      %PostInEdit{}

      iex> get_post_in_edit!(456)
      ** (Ecto.NoResultsError)

  """
  def get_post_in_edit!(id), do: Repo.get!(PostInEdit, id)

  @doc """
  Creates a post_in_edit.

  ## Examples

      iex> create_post_in_edit(%{field: value})
      {:ok, %PostInEdit{}}

      iex> create_post_in_edit(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_post_in_edit(attrs \\ %{}) do
    %PostInEdit{}
    |> PostInEdit.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a post_in_edit.

  ## Examples

      iex> update_post_in_edit(post_in_edit, %{field: new_value})
      {:ok, %PostInEdit{}}

      iex> update_post_in_edit(post_in_edit, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_post_in_edit(%PostInEdit{} = post_in_edit, attrs) do
    post_in_edit
    |> PostInEdit.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a post_in_edit.

  ## Examples

      iex> delete_post_in_edit(post_in_edit)
      {:ok, %PostInEdit{}}

      iex> delete_post_in_edit(post_in_edit)
      {:error, %Ecto.Changeset{}}

  """
  def delete_post_in_edit(%PostInEdit{} = post_in_edit) do
    Repo.delete(post_in_edit)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking post_in_edit changes.

  ## Examples

      iex> change_post_in_edit(post_in_edit)
      %Ecto.Changeset{source: %PostInEdit{}}

  """
  def change_post_in_edit(%PostInEdit{} = post_in_edit) do
    PostInEdit.changeset(post_in_edit, %{})
  end

  ###### COMMENTS ########
  alias APReifsteck.Media.Comment

  def get_comment!(id), do: Repo.get!(Comment, id)

  def get_post_comments(post = %Post{}) do
    Repo.preload(post, :comments).comments
  end

  def create_comment(%Post{} = post, %{"author_id" => author_id} = attrs \\ %{}) do
    # We are given a comment with a post id, which may reference an edit. We want to coerce the post id to
    # be the root post id so we don't have to muck with aggregating comments across post edits.
    # The assumption is that we want comments to show up dispite the particular post edit the comment was made for.
    if post.enable_comments do
      post
      |> Media.get_root_post()
      |> Ecto.build_assoc(:comments)
      |> Ecto.Changeset.change()
      |> Ecto.Changeset.put_change(:author_id, author_id)
      |> Comment.changeset(attrs)
      |> Repo.insert()
    else
      {:error, "This post does not allow comments"}
    end
  end

  def update_comment(%Comment{} = comment, attrs \\ %{}) do
    comment
    |> Comment.changeset(attrs)
    |> Repo.update()
  end
end
