defmodule APReifsteckWeb.PostController do
  use APReifsteckWeb, :controller
  use APReifsteckWeb.ProtectedResource

  alias APReifsteck.Media
  alias APReifsteck.Media.Post

  action_fallback APReifsteckWeb.FallbackController

  defimpl ProtectedResource, for: Post do
    def get(_resource, user, id), do: PR.get_protected_resource(Media, :get_post, user, id)

    def get!(_resource, user, id), do: PR.get_protected_resource(Media, :get_post!, user, id)
  end

  # By default, users can only CRUD their stuff. TODO: make an admin route to RUD on posts not thier own.

  # TODO: find the best way to render edits inside of a post, but not render those edits themselves
  # at the root level when you return -- keep the data uncluttered by repeat information.
  def index(conn, _params, _user) do
    posts = Media.list_posts()
    render(conn, "index.json", posts: posts)
  end

  def create(conn, post_params, user) do
    with {:ok, %Post{} = post} <- Media.create_post(post_params, user) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.post_path(conn, :show, post))
      |> render("show.json", post: post)
    end
  end

  # TODO: find the best way to render edits inside of a post
  def show(conn, %{"id" => id}, _user) do
    with {:ok, post} <- Media.get_post(id) do
      render(conn, "show.json", post: post)
    end
  end

  def update(conn, %{"id" => id, "post" => post_params}, user) do
    with {:ok, post = %Post{}} <- ProtectedResource.get(struct(Post), user, id),
         {:ok, post = %Post{}} <- Media.update_post(post, post_params) do
      render(conn, "show.json", post: post)
    end
  end

  def delete(conn, %{"id" => id}, user) do
    with {:ok, post = %Post{}} <- ProtectedResource.get(struct(Post), user, id),
         {:ok, %Post{}} <- Media.delete_post(post) do
      send_resp(conn, :no_content, "")
    end
  end
end
