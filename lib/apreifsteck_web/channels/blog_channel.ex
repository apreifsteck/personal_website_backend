defmodule APReifsteckWeb.BlogChannel do
  use APReifsteckWeb, :channel

  def join("blog:create", params, socket) do
    {:ok, socket}
  end
end
