defmodule APReifsteckWeb.PostInEditController do
  use APReifsteckWeb, :controller

  alias APReifsteck.Media
  alias APReifsteck.Media.PostInEdit

  action_fallback APReifsteckWeb.FallbackController

  def index(conn, _params) do
    posts_in_edit = Media.list_posts_in_edit()
    render(conn, "index.json", posts_in_edit: posts_in_edit)
  end

  def create(conn, %{"post_in_edit" => post_in_edit_params}) do
    with {:ok, %PostInEdit{} = post_in_edit} <- Media.create_post_in_edit(post_in_edit_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.post_in_edit_path(conn, :show, post_in_edit))
      |> render("show.json", post_in_edit: post_in_edit)
    end
  end

  def show(conn, %{"id" => id}) do
    post_in_edit = Media.get_post_in_edit!(id)
    render(conn, "show.json", post_in_edit: post_in_edit)
  end

  def update(conn, %{"id" => id, "post_in_edit" => post_in_edit_params}) do
    post_in_edit = Media.get_post_in_edit!(id)

    with {:ok, %PostInEdit{} = post_in_edit} <-
           Media.update_post_in_edit(post_in_edit, post_in_edit_params) do
      render(conn, "show.json", post_in_edit: post_in_edit)
    end
  end

  def delete(conn, %{"id" => id}) do
    post_in_edit = Media.get_post_in_edit!(id)

    with {:ok, %PostInEdit{}} <- Media.delete_post_in_edit(post_in_edit) do
      send_resp(conn, :no_content, "")
    end
  end
end
