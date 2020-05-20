defmodule APReifsteckWeb.PostView do
  use APReifsteckWeb, :view
  alias APReifsteckWeb.PostView

  def render("index.json", %{posts: posts}) do
    %{data: render_many(posts, PostView, "post.json")}
  end

  def render("show.json", %{post: post}) do
    %{data: render_one(post, PostView, "post.json")}
  end

  def render("post.json", %{post: post}) do
    %{
      id: post.id,
      title: post.title,
      body: post.body,
      enable_comments: post.enable_comments,
      root_id: post.root_id,
      edits:
        if(Ecto.assoc_loaded?(post.children),
          do: render_many(post.children, PostView, "post.json"),
          else: nil
        )
    }
  end
end
