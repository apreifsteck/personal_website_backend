defmodule APReifsteckWeb.PostController do
  use APReifsteckWeb, :controller

  alias APReifsteck.Media
  alias APReifsteck.Media.Post

  action_fallback APReifsteckWeb.FallbackController

  def index(conn, _params) do
    posts = Media.list_posts()
    render(conn, "index.json", posts: posts)
  end

  def create(conn, %{"post" => post_params}) do
    with {:ok, %Post{} = post} <- Media.create_post(post_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.post_path(conn, :show, post))
      |> render("show.json", post: post)
    end
  end

  def show(conn, %{"id" => id}) do
    post = Media.get_post!(id)
    render(conn, "show.json", post: post)
  end

  def update(conn, %{"id" => id, "post" => post_params}) do
    post = Media.get_post!(id)

    with {:ok, %Post{} = post} <- Media.update_post(post, post_params) do
      render(conn, "show.json", post: post)
    end
  end

  def delete(conn, %{"id" => id}) do
    post = Media.get_post!(id)

    with {:ok, %Post{}} <- Media.delete_post(post) do
      send_resp(conn, :no_content, "")
    end
  end
end
