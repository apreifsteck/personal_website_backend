defmodule APReifsteck.TestHelpers do
  alias APReifsteck.{
    Accounts,
    Accounts.User,
    Media,
    Repo
  }

  def user_fixture(attrs \\ %{}) do
    user =
      %User{}
      |> User.changeset(%{
        name: "Test Testman",
        uname: "testing",
        email: "test@example.com",
        password: "secretpassword",
        password_confirmation: "secretpassword"
      })
      |> Repo.insert!()

    Map.replace!(user, :password, nil)
  end

  defp random_string(length) do
    :crypto.strong_rand_bytes(length) |> Base.url_encode64() |> binary_part(0, length)
  end

  def random_user(attrs \\ %{}) do
    password = random_string(14)

    user =
      %User{}
      |> User.changeset(%{
        name: random_string(12),
        uname: random_string(8),
        email: random_string(12) <> "@example.com",
        password: password,
        password_confirmation: password
      })
      |> Repo.insert!()

    Map.replace!(user, :password, nil)
  end

  def image_fixture(user, attrs \\ %{}) do
    attrs =
      attrs
      |> Enum.into(%{
        "title" => "A title",
        "description" => "A description",
        "image" => %Plug.Upload{
          path: "test/test_assets/images/test_img.png",
          filename: "test_img.png"
        }
      })

    {:ok, image} = Media.create_image(user, attrs)

    image
  end
end
