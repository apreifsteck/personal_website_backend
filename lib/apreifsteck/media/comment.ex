defmodule APReifsteck.Media.Comment do
  use Ecto.Schema
  import Ecto.Changeset

  schema "comments" do
    field :body, :string
    field :edited, :boolean, default: false
    belongs_to :post, APReifsteck.Media.Post
    belongs_to :author, APReifsteck.Accounts.User, foreign_key: :author_id

    belongs_to :parent_comment, APReifsteck.Media.Comment,
      foreign_key: :parent_comment_id,
      references: :id

    # define_field: false
    timestamps()
  end

  @doc false
  def changeset(comment, attrs) do
    comment
    |> cast(attrs, [:body])
    |> maybe_set_parent_comment_id(attrs)
    |> maybe_update_edited()
    |> assoc_constraint(:post)
    |> assoc_constraint(:author)
    |> assoc_constraint(:parent_comment)
    |> validate_required([:body])
  end

  defp maybe_set_parent_comment_id(comment, attrs \\ %{}) do
    case fetch_field(comment, :parent_comment_id) do
      {_, nil} -> cast(comment, attrs, [:parent_comment_id])
      _ -> comment
    end
  end

  defp maybe_update_edited(comment) do
    case fetch_field(comment, :id) do
      {_, nil} -> comment
      _ -> put_change(comment, :edited, true)
    end
  end
end
