defmodule APReifsteckWeb.ImageControllerTest do
  use APReifsteckWeb.ConnCase

  alias APReifsteck.Media
  alias APReifsteck.Media.Image

  @test_dir "uploads/test"
  @create_attrs %{
    "title" => "Test Image",
    "description" => "An image I use for testing things",
    "image" => %Plug.Upload{
      path: "test/test_assets/images/test_img.png",
      filename: "test_img.png"
    },
    "is_gallery_img" => true
  }
  @update_attrs %{"description" => "An updated description"}
  @invalid_attrs %{
    "title" => nil,
    "description" => nil,
    "image" => nil
  }

  def fixture(:image, %{user: user} = context) do
    {:ok, image} = Media.create_image(user, @create_attrs)
    image
  end

  setup %{conn: conn} do
    user = user_fixture()

    conn =
      conn
      |> Plug.Conn.assign(:current_user, user)
      |> put_req_header("accept", "application/json")

    # This is the conn object we'll use to represent a malicious user
    mconn = Plug.Conn.assign(conn, :current_user, random_user())

    on_exit(fn ->
      case File.ls(@test_dir) do
        {:ok, img_list} ->
          Enum.each(img_list, &File.rm/1)

        _ ->
          nil
      end

      File.rmdir(@test_dir)
    end)

    {:ok, conn: conn, mal_conn: mconn, user: user}
  end

  describe "index" do
    setup [:create_image]

    test "lists all user images", %{conn: conn, user: user, image: image} do
      # IO.inspect(image)
      conn = get(conn, Routes.image_path(conn, :index, %{"user_id" => user.id, "is_gallery_img" => true}))
      assert json_response(conn, 200)["data"] != []
    end
  end

  describe "create image" do
    test "renders image when data is valid", %{conn: conn, user: user} do
      conn = post(conn, Routes.image_path(conn, :create), @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, Routes.image_path(conn, :show, id))

      assert %{
               "id" => id,
               "filename" => filename,
               "url" => url,
               "is_gallery_img" => is_gallery_img
             } = json_response(conn, 200)["data"]
      # url = "/media/test/#{user.id}/#{filename}"
      conn = get(conn, url)
      assert response(conn, 200)
      assert is_gallery_img == true
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.image_path(conn, :create), @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update image" do
    setup [:create_image]

    test "renders image when data is valid", %{conn: conn, image: %Image{id: id} = image} do
      conn = put(conn, Routes.image_path(conn, :update, image), @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, Routes.image_path(conn, :show, id))

      assert %{
               "id" => id
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, image: image} do
      conn = put(conn, Routes.image_path(conn, :update, image), @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end

    test "cannot update an image for a different user", %{
      conn: conn,
      mal_conn: mconn,
      image: image
    } do
      assert false
    end
  end

  describe "delete image" do
    setup [:create_image]

    test "deletes chosen image", %{conn: conn, image: image} do
      conn = delete(conn, Routes.image_path(conn, :delete, image))
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, Routes.image_path(conn, :show, image))
      end
    end
  end

  defp create_image(context) do
    image = fixture(:image, context)
    {:ok, image: image}
  end
end
