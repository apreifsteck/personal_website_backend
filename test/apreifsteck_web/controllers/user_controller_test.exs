defmodule APReifsteckWeb.UserControllerTest do
  use APReifsteckWeb.ConnCase

  alias APReifsteck.Accounts
  alias APReifsteck.Accounts.User
  alias APReifsteck.Repo
  alias APReifsteckWeb.Endpoint
  @password "secret1234"

  @create_params %{
    "user" => %{
      "name" => "Test Testman",
      "uname" => "test",
      "email" => "test@example.com",
      "password" => @password,
      "password_confirmation" => @password
    }
  }
  @invalid_params %{
    "user" => %{"email" => "invalid", "password" => @password, "password_confirmation" => ""}
  }

  @update_attrs %{
    email: "some updated email",
    name: "some updated name",
    password_hash: "some updated password_hash",
    uname: "some updated uname"
  }
  @invalid_attrs %{email: nil, name: nil, password_hash: nil, uname: nil}

  def fixture(:user) do
    # Create a user
    # Put/make sure they are in the session (i.e, authenticate them)
  end

  setup %{conn: conn} do
    conn = %{conn | secret_key_base: Endpoint.config(:secret_key_base)}
    config = [otp_app: :apreifsteck]

    user =
      Repo.insert!(%User{
        id: 1,
        email: "test@example.com",
        name: "Testman Test",
        uname: "testuser"
      })

    {conn, user} = APReifsteckWeb.APIAuthPlug.create(conn, user, config)
    conn = Pow.Plug.assign_current_user(conn, user, config)

    {:ok, conn: put_req_header(conn, "accept", "application/json"), user: user}
  end

  # TODO: should only be able to do this if they are an admin
  # describe "index" do
  #   test "lists all users", %{conn: conn} do
  #     conn = get(conn, Routes.user_path(conn, :index))
  #     assert json_response(conn, 200)["data"] == []
  #   end
  # end

  describe "render user" do
    test "renders user when data is valid", %{conn: conn, user: user} do
      conn = get(conn, Routes.user_path(conn, :show, user.id))

      assert %{
               "id" => id,
               "email" => "test@example.com",
               "name" => "Testman Test",
               "uname" => "testuser"
             } = json_response(conn, 200)["data"]
    end

    # TODO: Render something when the user isn't found/invalid user id
    # test "renders errors when data is invalid", %{conn: conn, user: user} do
    #   conn = post(conn, Routes.user_path(conn, :create), user: @invalid_attrs)
    #   assert json_response(conn, 422)["errors"] != %{}
    # end
  end

  describe "update user" do
    setup [:create_user]

    test "renders user when data is valid", %{conn: conn, user: %User{id: id} = user} do
      conn = put(conn, Routes.user_path(conn, :update, user), user: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, Routes.user_path(conn, :show, id))

      assert %{
               "id" => id,
               "email" => "some updated email",
               "name" => "some updated name",
               "password_hash" => "some updated password_hash",
               "uname" => "some updated uname"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, user: user} do
      conn = put(conn, Routes.user_path(conn, :update, user), user: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete user" do
    test "deletes chosen user", %{conn: conn, user: user} do
      conn = delete(conn, Routes.user_path(conn, :delete, user))
      assert response(conn, 204)
      IO.inspect(get(conn, Routes.user_path(conn, :show, user)))

      # assert_error_sent 404, fn ->
      # get(conn, Routes.user_path(conn, :show, user))
      # end
    end
  end

  defp create_user(_) do
    user = fixture(:user)
    {:ok, user: user}
  end
end
