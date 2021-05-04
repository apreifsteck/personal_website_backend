defmodule APReifsteckWeb.ProtectedResource do
  alias APReifsteck.Accounts.User

  def get_protected_resource(module, getter_func, %User{} = user, id, opts \\ []) do
    with {:ok, resource} <- apply(module, getter_func, [id]) do
      if Map.get(resource, opts[:uid_key] || :user_id) == user.id do
        {:ok, resource}
      else
        {:error, "This user does not have access to this resource"}
      end
    end
  end

  def get_protected_resource!(module, getter_func, %User{} = user, id, opts \\ []) do
    case get_protected_resource(module, getter_func, user, id, opts) do
      {:ok, resource} -> resource
      {:error, msg} -> raise(msg)
    end
  end
end

defprotocol ProtectedResource do
  def get(user, id)

  def get!(user, id)
end
