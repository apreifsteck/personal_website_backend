defmodule APReifsteckWeb.PostInEditView do
  use APReifsteckWeb, :view
  alias APReifsteckWeb.PostInEditView

  def render("index.json", %{posts_in_edit: posts_in_edit}) do
    %{data: render_many(posts_in_edit, PostInEditView, "post_in_edit.json")}
  end

  def render("show.json", %{post_in_edit: post_in_edit}) do
    %{data: render_one(post_in_edit, PostInEditView, "post_in_edit.json")}
  end

  def render("post_in_edit.json", %{post_in_edit: post_in_edit}) do
    %{id: post_in_edit.id}
  end
end
