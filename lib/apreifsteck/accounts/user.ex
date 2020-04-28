defmodule APReifsteck.Accounts.User do
  use Ecto.Schema
  use Pow.Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    # field :email, :string
    field :name, :string
    field :uname, :string
    pow_user_fields()
    # field :password_hash, :string
    # field :password, :string, virtual: true
    has_many :images, APReifsteck.Media.Image, foreign_key: :id

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> pow_changeset(attrs)
    |> cast(attrs, [:name, :uname, :email])
    |> validate_required([:name, :uname])
    |> validate_length(:uname, min: 1, max: 20)
    |> unique_constraint(:uname)
  end

  def registration_changeset(user, attrs) do
    user
    |> changeset(attrs)
    |> cast(attrs, [:password])
    |> validate_required([:password])
    |> validate_length(:password, min: 6, max: 100)
    |> put_pass_hash()
    |> put_change(:password, nil)
  end

  def put_pass_hash(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{password: pass}} ->
        put_change(changeset, :password_hash, Pbkdf2.hash_pwd_salt(pass))

      _ ->
        changeset
    end
  end
end
