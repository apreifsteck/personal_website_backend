defmodule APReifsteckWeb.BlogChannel do
  use APReifsteckWeb, :channel

  def join("blog_create:" <> uid, params, socket) do
    if socket.assigns.user_id == String.to_integer(uid) do
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_in("image", payload, socket) do
    IO.inspect(payload)
    IO.inspect(socket)
    {:reply, :ok, socket}
  end

  def handle_in("body", payload, socket) do

  end

  def handle_in("title", payload, socket) do

  end

end
