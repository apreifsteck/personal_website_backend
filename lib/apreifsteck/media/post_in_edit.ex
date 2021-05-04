defmodule APReifsteck.Media.PostInEdit do
  @moduledoc """
  This schema is sort of a staging area for posts that are undergoing an edit. This can be a new post, or 
  an existing post. The purpose of this is that if you track what is being edited, you can associate images 
  or other media with this transient post. That way, when a user uploads an image by pasting it into the 
  editing field, we can associate that image with the transient post. If the post edit is canceled, you can
  delete all images from the fs that were uploaded in the making of the post edit. If the post is submitted,
  you can copy all images over to the newly created post/post edit.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "posts_in_edit" do
    belongs_to :user, APReifsteck.Accounts.User
    belongs_to :parent, APReifsteck.Media.Post
    many_to_many :images, APReifsteck.Media.Image, join_through: "posts_in_edit_images"
    timestamps()
  end

  @doc false
  def changeset(post_in_edit, attrs) do
    post_in_edit
    |> cast(attrs, [])
    |> validate_required([])
  end
end
