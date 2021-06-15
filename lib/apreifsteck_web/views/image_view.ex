defmodule APReifsteckWeb.ImageView do
  use APReifsteckWeb, :view
  alias APReifsteckWeb.ImageView
  alias APReifsteck.Uploaders.Image, as: Uploader

  def render("index.json", %{images: images}) do
    %{data: render_many(images, ImageView, "image.json")}
  end

  def render("show.json", %{image: image}) do
    %{data: render_one(image, ImageView, "image.json")}
  end

  def render("image.json", %{image: image}) do
    url =
      Uploader.url({image.filename, %{id: image.user_id}})
      |> String.replace_prefix("/uploads", "/media")
    %{
      id: image.id,
      filename: image.filename,
      description: image.description,
      title: image.title,
      url: url,
      is_gallery_img: image.is_gallery_img
    }
  end
end
