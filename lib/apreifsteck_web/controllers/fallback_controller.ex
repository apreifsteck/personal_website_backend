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

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(APReifsteckWeb.ErrorView)
    |> render(:"404")
  end

  def call(conn, {:error, messsage}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(APReifsteckWeb.ErrorView)
    |> render("error.json", messsage)
  end
end
