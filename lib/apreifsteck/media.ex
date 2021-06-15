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

  def list_user_images(uid, params) do
    query = from(img in Image, where: img.user_id == ^uid)
    params
    |> Enum.map(fn {query_param, param_val} -> {String.to_existing_atom(query_param), param_val} end)
    |> Enum.reduce(query, fn {q_param, q_value}, acc_query ->
      acc_query |> where([q], field(q, ^q_param) == ^q_value)
    end)
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

  def get_image(id) do
    case image = Repo.get(Image, id) do
      nil -> {:error, :not_found}
      _ -> {:ok, image}
    end
  end

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
  def delete_image(%Image{} = image) do
    user = image |> Repo.preload(:user) |> Map.fetch!(:user)
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

  def create_post(_params, nil), do: {:error, "must supply a user when creating a post"}

  def create_post(params, user) do
    # parse out links of images in the post that made the final cut
    get_imgs_from_post_body(params["body"] || "")
    # Diff the list with those from the images that were posted during the making of the post
    # Delete those images not in the list
     |> prune_unused_uploads(params["img_ids"] || [])
    user
    |> Ecto.build_assoc(:posts)
    |> Post.changeset(params)
    |> Repo.insert()
  end

  def prune_unused_uploads(referenced_imgs, img_ids) when length(img_ids) >= length(referenced_imgs) do
    # Delete any images that were uploaded during the creation of a post, but are not present in the
    # final submission
    alias APReifsteck.Uploaders.Image, as: Uploader
    unused_imgs =
      from(i in Image,
        where: i.id in ^img_ids,
        select: [:filename, :user_id, :id],
      )
      |> Repo.all()
      # We have to do this stupid filename translation becuase of the way waffle 'calculates' file names
      |> Enum.map(fn img ->
        Map.put(img, :filename, Uploader.filename(img))
      end)
      # Find any images that are not referenced in the post
      |> Enum.filter(fn img -> !Enum.member?(referenced_imgs, img.filename) end)
      |> Enum.map(&(&1.id))

      from(i in Image,
      where: i.id in ^unused_imgs
    )
    # Then delete them
    |> Repo.delete_all()
  end

  def get_imgs_from_post_body(body) do
    Regex.scan(~r/\[img\]\(https?:.*\/media\/\w+\/\d+\/(.*)\)/, body)
      |> Enum.map(&tl/1)
      |> Enum.map(&hd/1)
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

  def get_latest_edit(id) when is_integer(id) do
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

  def delete_post(%Post{} = post) do
    with {:ok, %Post{}} = result when is_nil(post.root_id) <- Repo.delete(post) do
      result
    else
      {:error, %Ecto.Changeset{} = changest} ->
        {:error, changest.errors}

      _ ->
        {:error, "you can only delete posts from the root post"}
    end
  end

  def update_post(%Post{} = post, attrs) do
    latest_post_id = get_latest_edit(post).id

    if post.id == latest_post_id do
      post
      |> Repo.preload([:user, :root])
      |> Post.create_edit(attrs)
      |> Repo.insert()
      |> case do
        {:ok, _} = updated_post ->
          updated_post

        {:error, %Ecto.Changeset{} = changest} ->
          {:error, changest}

        {:error, _} = error ->
          error
      end
    else
      {:error, "may only edit the latest version of the post"}
    end
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
