defmodule APReifsteckWeb.UserController do
  use APReifsteckWeb, :controller
  use APReifsteckWeb.ProtectedResource

  alias APReifsteck.Accounts
  alias APReifsteck.Accounts.User

  action_fallback APReifsteckWeb.FallbackController

  defimpl ProtectedResource, for: User do
    def get(_resource, user, id), do: PR.get_protected_resource(Accounts, :get_user, user, id, uid_key: :id)
    def get!(_resource, user, id), do: PR.get_protected_resource!(Accounts, :get_user!, user, id, uid_key: :id)
  end


  def index(conn, _params, _user) do
    users = Accounts.list_users()
    render(conn, "index.json", users: users)
  end

  def show(conn, %{"id" => id}, _user) do
    user = Accounts.get_user!(id)
    render(conn, "show.json", user: user)
  end

  def show(conn, %{"uname" => uname}, _user) do
    with {:ok, user} <- Accounts.get_user_by(uname: uname) do
      render(conn, "show.json", user: user)
    end
  end

  def update(conn, %{"id" => id, "user" => user_params}, user) do
    with {:ok, user = %User{}} <- ProtectedResource.get(struct(User), user, id),
         {:ok, %User{} = user} <- Accounts.update_user(user, user_params) do
      render(conn, "show.json", user: user)
    end
  end

  def delete(conn, %{"id" => id}, user) do
    with {:ok, user = %User{}} <- ProtectedResource.get(struct(User), user, id),
         {:ok, %User{}} <- Accounts.delete_user(user) do
      send_resp(conn, :no_content, "")
    end
  end
end
