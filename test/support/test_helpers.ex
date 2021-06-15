defmodule APReifsteck.TestHelpers do
  # alias APReifsteckWeb.Router.Helpers, as: Routes
  # import Phoenix.ConnTest
  alias APReifsteck.{
    Accounts,
    Accounts.User,
    Media,
    Media.Post,
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

  def random_string(length) do
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

  def post_fixture(user, attrs \\ %{}) do
    {:ok, post} =
      Media.create_post(
        %{
          "title" => attrs["title"] || "POST TITLE",
          "body" => attrs["body"] || "some post body",
          "enable_comments" => attrs["enable_comments"] || true
        },
        user
      )

    post
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
