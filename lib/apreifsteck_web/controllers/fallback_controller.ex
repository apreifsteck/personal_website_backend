defmodule APReifsteckWeb.FallbackController do
  @moduledoc """
  Translates controller action results into valid `Plug.Conn` responses.

  See `Phoenix.Controller.action_fallback/1` for more details.
  """
  use APReifsteckWeb, :controller

  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(APReifsteckWeb.ChangesetView)
    |> render("error.json", changeset: changeset)
  end

  # This is for entities that are not found
  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(APReifsteckWeb.ErrorView)
    |> render(:"404")
  end

  # This is for routes that are not found
  def call(conn, :not_found) do
    conn
    |> put_status(:not_found)
    |> put_view(APReifsteckWeb.ErrorView)
    |> render(:"404")
  end

  def call(conn, {:error, :unauthorized}) do
    conn
    |> put_status(:unauthorized)
    |> put_view(APReifsteckWeb.ErrorView)
    |> render(:"401")
  end

  def call(conn, {:error, message}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(APReifsteckWeb.ErrorView)
    |> render("error.json", %{detail: message})
  end
end
