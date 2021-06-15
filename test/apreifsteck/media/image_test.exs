defmodule APReifsteck.ImageTest do
  use APReifsteck.DataCase, async: true

  alias APReifsteck.Media
  alias APReifsteck.Uploaders
  alias APReifsteck.Repo

  alias APReifsteck.Media.Image

  @valid_attrs %{
    "title" => "A title",
    "description" => "A description",
    "image" => %Plug.Upload{
      path: "test/test_assets/images/test_img.png",
      filename: "test_img.png"
    },
    "is_gallery_img" => true
  }
  @update_attrs %{
    "title" => "Some other title",
    "description" => "You know, descriptive"
  }
  @invalid_update_attrs %{
    "title" => "Some other title",
    "description" => "You know, descriptive",
    "image" => %Plug.Upload{
      path: "test/test_assets/images/another_test_img.png",
      filename: "another_test_img.png"
    }
  }
  @invalid_attrs %{}

  describe "create_image/2" do
    setup do
      {:ok, user: user_fixture()}
    end

    @tag :create_image
    test "create_image/1 with valid data creates a image", %{user: user} do
      assert {:ok, %Image{} = image} = Media.create_image(user, @valid_attrs)
      assert image.is_gallery_img == true
    end

    test "create_image/1 with invalid data returns error changeset", %{user: user} do
      assert {:error, %Ecto.Changeset{}} = Media.create_image(user, @invalid_attrs)
    end
  end

  describe "update_image/2" do
    setup do
      {:ok, user: user_fixture()}
    end

    @tag :update_image
    test "update_image/2 with valid data updates the image", %{user: user} do
      image = image_fixture(user)
      assert {:ok, %Image{} = image} = Media.update_image(image, @update_attrs)
      assert image.title == @update_attrs["title"]
      assert image.description == @update_attrs["description"]
    end

    @tag :update_image
    test "update_image/2 when trying to modify image object returns error changeset", %{
      user: user
    } do
      image = image_fixture(user) |> Repo.preload(:user)
      assert {:error, %Ecto.Changeset{}} = Media.update_image(image, @invalid_update_attrs)
      assert image == Media.get_image!(image.id) |> Repo.preload(:user)
    end

    # test "change_image/1 returns a image changeset", %{user: user} do
    #   image = image_fixture(user)
    #   assert %Ecto.Changeset{} = Media.change_image(image)
    # end
  end

  describe "delete/2" do
    setup do
      user = user_fixture()
      {:ok, user: user, image: image_fixture(user)}
    end

    @tag :delete_image
    test "delete_image/2 deletes the image from the database", %{user: user, image: image} do
      assert {:ok, %Image{}} = Media.delete_image(image)
      assert_raise Ecto.NoResultsError, fn -> Media.get_image!(image.id) end
    end

    @tag :delete_image
    test "delete_image/2 deletes the image from the filesystem", %{user: user, image: image} do
      img_path = "." <> Uploaders.Image.url({image.filename, user})
      assert File.exists?(img_path)

      assert {:ok, %Image{}} = Media.delete_image(image)
      :timer.sleep(200)
      refute File.exists?(img_path)
    end
  end

  describe "list_images/0" do
    setup do
      {:ok, user: user_fixture()}
    end

    test "list_images/0 returns all images", %{user: user} do
      image = image_fixture(user) |> Repo.preload(:user)
      assert Media.list_images() |> Repo.preload(:user) == [image]
    end
  end

  describe "get_image/1" do
    setup do
      {:ok, user: user_fixture()}
    end

    test "get_image!/1 returns the image with given id", %{user: user} do
      image = image_fixture(user) |> Repo.preload(:user)
      assert Media.get_image!(image.id) |> Repo.preload(:user) == image
    end
  end
end
