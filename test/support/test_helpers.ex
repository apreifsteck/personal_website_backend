defmodule APReifsteck.TestHelpers do
  alias APReifsteck.{
    Accounts,
    Media
  }

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> Enum.into(%{
        name: "Some User",
        uname: "user#{System.unique_integer([:positive])}",
        password: attrs[:password] || "supersecret"
      })
      |> Accounts.create_user()

    user
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
