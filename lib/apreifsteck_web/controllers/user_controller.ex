defmodule APReifsteckWeb.UserController do
  use APReifsteckWeb, :controller

  alias APReifsteck.Accounts
  alias APReifsteck.Accounts.User

  action_fallback APReifsteckWeb.FallbackController

  # TODO: Add a plug so that you can only do these operations if the id you're asking for is the same as the current user in the connection
  def index(conn, _params) do
    users = Accounts.list_users()
    render(conn, "index.json", users: users)
  end

  def show(conn, %{"id" => id}) do
    user = Accounts.get_user!(id)
    render(conn, "show.json", user: user)
  end

  def show(conn, %{"uname" => uname}) do
    with {:ok, user} <- Accounts.get_user_by(uname: uname) do
      render(conn, "show.json", user: user)
    end
  end

  def update(conn, %{"id" => id, "user" => user_params}) do
    user = Accounts.get_user!(id)

    with {:ok, %User{} = user} <- Accounts.update_user(user, user_params) do
      render(conn, "show.json", user: user)
    end
  end

  def delete(conn, %{"id" => id}) do
    user = Accounts.get_user!(id)

    with {:ok, %User{}} <- Accounts.delete_user(user) do
      send_resp(conn, :no_content, "")
    end
  end
end
