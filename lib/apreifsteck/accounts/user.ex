defmodule APReifsteck.Accounts.User do
  use Ecto.Schema

  use Pow.Ecto.Schema,
    user_id_field: :uname

  import(Ecto.Changeset)

  schema "users" do
    field :email, :string
    field :name, :string
    field :uname, :string
    pow_user_fields()
    has_many :images, APReifsteck.Media.Image, foreign_key: :user_id
    has_many :posts, APReifsteck.Media.Post, foreign_key: :user_id
    # has_many :comments, APReifsteck.Media.Comment, for

    timestamps()
  end

  # TODO implement separate change password functionality

  @doc false
  def changeset(user, attrs) do
    user
    |> maybe_change_password(attrs)
    |> cast(attrs, [:name, :uname, :email])
    |> validate_required([:name, :uname])
    |> validate_length(:uname, min: 1, max: 20)
    |> validate_change(:email, &validate_email(&1, &2))
    |> unique_constraint(:uname)
  end

  defp maybe_change_password(user, attrs) do
    case attrs do
      # You need both because it seems like the session controller converts them to atoms
      # but the user and registration controller do not
      # EDIT: could also just be how I have the insert defined in the test code.
      # TODO: possibly clean up later, not a high priority
      %{password: _} ->
        pow_changeset(user, attrs)

      %{"password" => _} ->
        pow_changeset(user, attrs)

      _ ->
        change(user, password_hash: user.password_hash)
    end
  end

  defp validate_email(:email, email) do
    # The docs said you're never supposed to call this directly, but it also only get's called if the user_id_field is set to email. So. Sorry buds.
    case Pow.Ecto.Schema.Changeset.validate_email(email) do
      :ok -> []
      {:error, err} -> [email: err]
    end
  end
end
