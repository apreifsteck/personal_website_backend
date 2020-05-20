defmodule APReifsteckWeb.PostController do
  use APReifsteckWeb, :controller

  alias APReifsteck.Media
  alias APReifsteck.Media.Post

  action_fallback APReifsteckWeb.FallbackController

  # By default, users can only CRUD their stuff. TODO: make an admin route to RUD on posts not thier own.

  # posts is protected, so get the current user as a third argument to each action
  def action(conn, _) do
    args = [conn, conn.params, conn.assigns.current_user]
    apply(__MODULE__, action_name(conn), args)
  end

  # TODO: find the best way to render edits inside of a post, but not render those edits themselves
  # at the root level when you return -- keep the data uncluttered by repeat information.
  def index(conn, _params, _user) do
    posts = Media.list_posts()
    render(conn, "index.json", posts: posts)
  end

  def create(conn, %{"post" => post_params}, user) do
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
    with {:ok, post = %Post{}} <- Media.update_post(id, user, post_params) do
      render(conn, "show.json", post: post)
    end
  end

  def delete(conn, %{"id" => id}, user) do
    with {:ok, %Post{}} <- Media.delete_post(id, user) do
      send_resp(conn, :no_content, "")
    end
  end
end
