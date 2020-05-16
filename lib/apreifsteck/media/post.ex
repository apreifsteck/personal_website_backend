defmodule APReifsteck.Media.Post do
  use Ecto.Schema
  alias APReifsteck.Media.Post
  import Ecto.Changeset

  schema "posts" do
    field :title, :string
    field :body, :string
    field :enable_comments, :boolean
    field :root_id, :integer
    belongs_to :user, APReifsteck.Accounts.User

    belongs_to :root, Post,
      foreign_key: :root_id,
      references: :id,
      define_field: false

    has_many :children, Post,
      foreign_key: :root_id,
      references: :id,
      on_delete: :delete_all

    # define_field: false

    # has_one :post, Post, foreign_key: :next_hist
    timestamps()
  end

  @doc false
  def changeset(post, attrs) do
    post
    |> cast(attrs, [:title, :body, :enable_comments])
    |> assoc_constraint(:user)
    |> validate_required([:title, :body])
  end

  def create_edit(post, attrs) do
    # IO.inspect(post)

    changeset =
      %Post{}
      |> changeset(%{
        title: post.title,
        body: post.body,
        enable_comments: post.enable_comments
      })

    if post.root_id == nil do
      changeset
      |> put_change(:root_id, post.id)
    else
      changeset
      |> put_assoc(:root, post.root)
    end
    |> put_assoc(:user, post.user)
    |> changeset(attrs)
  end
end
