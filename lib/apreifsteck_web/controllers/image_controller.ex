defmodule APReifsteckWeb.ImageController do
  use APReifsteckWeb, :controller

  alias APReifsteck.Accounts
  alias APReifsteck.Media
  alias APReifsteck.Media.Image

  action_fallback APReifsteckWeb.FallbackController

  def index(conn, _params) do
    images = Media.list_images()
    render(conn, "index.json", images: images)
  end

  def user_index(conn, %{"user_id" => uid}) do
    images = Media.list_user_images(uid)
    # TODO: render something
    render(conn, "index.json", images: images)
  end

  def create(conn, %{"user_id" => user_id} = img_ob) do
    user = Accounts.get_user!(user_id)

    with {:ok, %Image{} = image} <- Media.create_image(user, img_ob) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.image_path(conn, :show, image))
      |> render("show.json", image: image)
    end
  end

  def show(conn, %{"id" => id}) do
    image = Media.get_image!(id)
    render(conn, "show.json", image: image)
  end

  def update(conn, %{"id" => id, "image" => image_params}) do
    image = Media.get_image!(id)

    with {:ok, %Image{} = image} <- Media.update_image(image, image_params) do
      render(conn, "show.json", image: image)
    end
  end

  def delete(conn, %{"image_id" => id, "user_id" => user_id}) do
    user = Accounts.get_user!(user_id)
    image = Media.get_image!(id)

    with {:ok, %Image{}} <- Media.delete_image(user, image) do
      send_resp(conn, :no_content, "")
    end
  end
end
