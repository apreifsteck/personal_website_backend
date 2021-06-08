defmodule APReifsteckWeb.CommentControllerTest do
  use APReifsteckWeb.ConnCase

  alias APReifsteck.Media
  alias APReifsteck.Media.Comment

  @create_attrs %{
    "body" => "valid comment body"
  }
  @update_attrs %{
    "body" => "updated body"
  }
  @invalid_attrs %{"body" => nil, "author_id" => nil}

  def fixture(:comment, context) do
    attrs =
      Map.merge(@create_attrs, %{
        "post_id" => context.post.id,
        "author_id" => context.post.user_id
      })

    {:ok, comment} = Media.create_comment(context.post, attrs)
    comment
  end

  def fixture(:user) do
    random_user()
  end

  def register_user(conn) do
    valid_params = %{
      "user" => %{
        "name" => "Test Testman",
        "uname" => "test",
        "email" => "test@example.com",
        "password" => "testpass",
        "password_confirmation" => "testpass"
      }
    }

    post(conn, Routes.registration_path(conn, :create, valid_params))
  end

  def fixture(:post) do
    {:ok, post} =
      Media.create_post(%{"title" => "Post Title", "body" => "Post Body", "img_ids" => []}, random_user())

    post
  end

  setup %{conn: conn} do
    registration_conn = register_user(conn)

    conn =
      conn
      |> put_req_header("accept", "application/json")
      |> Plug.Conn.assign(:current_user, registration_conn.assigns.current_user)

    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    setup [:create_post]

    test "lists all comments", %{conn: conn, post: post} do
      conn = get(conn, Routes.comment_path(conn, :index), %{"post_id" => post.id})
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create comment" do
    setup [:create_post, :create_user]

    test "renders comment when data is valid", %{conn: conn, post: post, user: user} do
      attrs = Map.merge(@create_attrs, %{"author_id" => user.id})
      conn = post(conn, Routes.comment_path(conn, :create), comment: attrs, post_id: post.id)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, Routes.comment_path(conn, :show, id))

      assert %{
               "id" => id
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, post: post} do
      conn =
        post(conn, Routes.comment_path(conn, :create), comment: @invalid_attrs, post_id: post.id)

      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update comment" do
    setup [:create_post, :create_comment]

    test "renders comment when data is valid", %{conn: conn, comment: %Comment{id: id} = comment} do
      conn = put(conn, Routes.comment_path(conn, :update, comment), comment: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, Routes.comment_path(conn, :show, id))

      assert %{
               "id" => id
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, comment: comment} do
      conn = put(conn, Routes.comment_path(conn, :update, comment), comment: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  # describe "delete comment" do
  #   setup [:create_comment]

  #   test "deletes chosen comment", %{conn: conn, comment: comment} do
  #     conn = delete(conn, Routes.comment_path(conn, :delete, comment))
  #     assert response(conn, 204)

  #     assert_error_sent 404, fn ->
  #       get(conn, Routes.comment_path(conn, :show, comment))
  #     end
  #   end
  # end

  defp create_comment(context) do
    comment = fixture(:comment, context)
    {:ok, comment: comment}
  end

  defp create_post(_) do
    {:ok, post: fixture(:post)}
  end

  defp create_user(_) do
    {:ok, user: random_user()}
  end
end
