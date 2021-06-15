defmodule APReifsteckWeb.ImageController do
  use APReifsteckWeb, :controller
  use APReifsteckWeb.ProtectedResource

  alias APReifsteck.Media
  alias APReifsteck.Media.Image

  action_fallback APReifsteckWeb.FallbackController

  defimpl ProtectedResource, for: Image do
    def get(_resource, user, id), do: PR.get_protected_resource(Media, :get_image, user, id)

    def get!(_resource, user, id), do: PR.get_protected_resource(Media, :get_image!, user, id)
  end

  def index(conn, %{"user_id" => id} = params, _user) do
    params = Map.delete(params, "user_id")
    images = Media.list_user_images(id, params)
    render(conn, "index.json", images: images)
  end

  def create(conn, img_ob, user) do
    with {:ok, %Image{} = image} <- Media.create_image(user, img_ob) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.image_path(conn, :show, image))
      |> render("show.json", image: image)
    end
  end

  def show(conn, %{"id" => id}, _user) do
    image = Media.get_image!(id)
    render(conn, "show.json", image: image)
  end

  def update(conn, %{"id" => id} = attrs, user) do
    with {:ok, %Image{} = image} <- ProtectedResource.get(struct(Image), user, id),
         {:ok, %Image{} = image} <- Media.update_image(image, attrs) do
      render(conn, "show.json", image: image)
    end
  end

  def delete(conn, %{"id" => id}, user) do
    with {:ok, %Image{} = image} <- ProtectedResource.get(struct(Image), user, id),
         {:ok, %Image{}} <- Media.delete_image(image) do
      send_resp(conn, :no_content, "")
    end
  end
end
