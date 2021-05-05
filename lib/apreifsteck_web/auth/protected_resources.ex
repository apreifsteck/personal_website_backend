defmodule APReifsteckWeb.ProtectedResource do

  # Injected into protected resources, so get the current user as a third argument to each action
  defmacro __using__(opts\\[]) do
    quote do
      alias APReifsteckWeb.ProtectedResource, as: PR
      def action(conn, _) do
        args = [conn, conn.params, conn.assigns.current_user]
        apply(__MODULE__, action_name(conn), args)
      end
    end
  end

  alias APReifsteck.Accounts.User

  def get_protected_resource(module, getter_func, %User{} = user, id, opts \\ []) do
    with {:ok, resource} <- apply(module, getter_func, [id]) do
      if Map.get(resource, opts[:uid_key] || :user_id) == user.id do
        {:ok, resource}
      else
        {:error, :unauthorized}
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
  def get(resource, user, id)

  def get!(resource, user, id)
end
