defmodule APReifsteck.Media.Post do
  use Ecto.Schema
  import Ecto.Changeset

  schema "posts" do
    field :title, :string
    field :body, :string
    field :enable_comments, :boolean
    field :prev_hist, :integer
    belongs_to :user, APReifsteck.Accounts.User

    belongs_to :parent, APReifsteck.Media.Post,
      foreign_key: :prev_hist,
      references: :id,
      define_field: false

    has_one :child, APReifsteck.Media.Post,
      foreign_key: :prev_hist,
      on_delete: :delete_all

    # define_field: false

    # has_one :post, APReifsteck.Media.Post, foreign_key: :next_hist
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
    Ecto.build_assoc(post, :child)
    |> changeset(%{
      title: post.title,
      body: post.body,
      enable_comments: post.enable_comments
    })
    |> put_assoc(:user, post.user)
    |> changeset(attrs)
  end
end
