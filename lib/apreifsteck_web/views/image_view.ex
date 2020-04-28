defmodule APReifsteckWeb.ImageView do
  use APReifsteckWeb, :view
  alias APReifsteckWeb.ImageView

  def render("index.json", %{images: images}) do
    %{data: render_many(images, ImageView, "image.json")}
  end

  def render("show.json", %{image: image}) do
    %{data: render_one(image, ImageView, "image.json")}
  end

  def render("image.json", %{image: image}) do
    %{id: image.id, filename: image.filename}
  end
end
