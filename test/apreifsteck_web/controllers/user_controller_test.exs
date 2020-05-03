defmodule APReifsteckWeb.UserControllerTest do
  use APReifsteckWeb.ConnCase

  alias APReifsteck.Accounts.User
  alias APReifsteck.Accounts
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

  setup %{conn: conn} do
    conn = %{conn | secret_key_base: Endpoint.config(:secret_key_base)}
    config = [otp_app: :apreifsteck]
    post(conn, Routes.registration_path(conn, :create, @create_params))
    user = Accounts.get_user_by!(uname: "test")
    # IO.inspect(user)
    conn = APReifsteckWeb.APIAuthPlug.do_create(conn, user, config)

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
               "name" => "Test Testman",
               "uname" => "test"
             } = json_response(conn, 200)["data"]
    end

    # TODO: Render something when the user isn't found/invalid user id
    # test "renders errors when data is invalid", %{conn: conn, user: user} do
    #   conn = post(conn, Routes.user_path(conn, :create), user: @invalid_attrs)
    #   assert json_response(conn, 422)["errors"] != %{}
    # end
  end

  @update_attrs %{
    email: "updated@email.com",
    name: "some updated name",
    uname: "some updated uname"
  }

  @invalid_attrs %{email: nil, name: nil, password_hash: nil, uname: nil}

  describe "update user" do
    test "renders user when data is valid", %{
      conn: conn,
      user: %User{id: id, password_hash: hash} = user
    } do
      resp_conn = put(conn, Routes.user_path(conn, :update, user), user: @update_attrs)

      assert %{"id" => ^id} = json_response(resp_conn, 200)["data"]

      conn = get(conn, Routes.user_path(conn, :show, id))

      assert %{
               "id" => id,
               "email" => "updated@email.com",
               "name" => "some updated name",
               "uname" => "some updated uname"
             } = json_response(conn, 200)["data"]
    end

    test "updating non-password fields keeps old password", %{
      conn: conn,
      user: %User{id: id, password_hash: hash} = user
    } do
      conn = put(conn, Routes.user_path(conn, :update, user), user: @update_attrs)
      assert response(conn, 200)
      assert ^hash = Accounts.get_user!(id).password_hash
    end

    test "renders errors when password_confirmation and current_password field not present when changing password",
         %{
           conn: conn,
           user: %User{id: id, password_hash: hash} = user
         } do
      attrs = @update_attrs |> Map.put(:password, "newPassword")
      conn = put(conn, Routes.user_path(conn, :update, user), user: attrs)
      updated_user? = Accounts.get_user!(id)
      assert ^hash = updated_user?.password_hash
      assert conn.status >= 400
    end

    test "updates password with valid input", %{
      conn: conn,
      user: %User{id: id, password_hash: hash} = user
    } do
      attrs =
        @update_attrs
        |> Map.merge(%{
          password: "newPassword",
          password_confirmation: "newPassword",
          current_password: @password
        })

      conn = put(conn, Routes.user_path(conn, :update, user), user: attrs)
      updated_user = Accounts.get_user!(id)
      assert hash != updated_user.password_hash
      assert conn.status == 200
    end

    test "renders errors when data is invalid", %{conn: conn, user: user} do
      conn = put(conn, Routes.user_path(conn, :update, user), user: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete user" do
    test "deletes chosen user", %{conn: conn, user: user} do
      resp_conn = delete(conn, Routes.user_path(conn, :delete, user))
      assert response(resp_conn, 204)

      assert_error_sent 404, fn ->
        get(conn, Routes.user_path(conn, :show, user))
      end
    end
  end
end
