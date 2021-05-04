defmodule APReifsteckWeb.PostInEditControllerTest do
  use APReifsteckWeb.ConnCase

  alias APReifsteck.Media
  alias APReifsteck.Media.PostInEdit

  @create_attrs %{}
  @update_attrs %{}
  @invalid_attrs %{}

  def fixture(:post_in_edit) do
    {:ok, post_in_edit} = Media.create_post_in_edit(@create_attrs)
    post_in_edit
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all posts_in_edit", %{conn: conn} do
      conn = get(conn, Routes.post_in_edit_path(conn, :index))
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create post_in_edit" do
    test "renders post_in_edit when data is valid", %{conn: conn} do
      conn = post(conn, Routes.post_in_edit_path(conn, :create), post_in_edit: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, Routes.post_in_edit_path(conn, :show, id))

      assert %{
               "id" => id
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.post_in_edit_path(conn, :create), post_in_edit: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update post_in_edit" do
    setup [:create_post_in_edit]

    test "renders post_in_edit when data is valid", %{
      conn: conn,
      post_in_edit: %PostInEdit{id: id} = post_in_edit
    } do
      conn =
        put(conn, Routes.post_in_edit_path(conn, :update, post_in_edit),
          post_in_edit: @update_attrs
        )

      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, Routes.post_in_edit_path(conn, :show, id))

      assert %{
               "id" => id
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, post_in_edit: post_in_edit} do
      conn =
        put(conn, Routes.post_in_edit_path(conn, :update, post_in_edit),
          post_in_edit: @invalid_attrs
        )

      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete post_in_edit" do
    setup [:create_post_in_edit]

    test "deletes chosen post_in_edit", %{conn: conn, post_in_edit: post_in_edit} do
      conn = delete(conn, Routes.post_in_edit_path(conn, :delete, post_in_edit))
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, Routes.post_in_edit_path(conn, :show, post_in_edit))
      end
    end
  end

  defp create_post_in_edit(_) do
    post_in_edit = fixture(:post_in_edit)
    {:ok, post_in_edit: post_in_edit}
  end
end
