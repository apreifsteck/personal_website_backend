defmodule APReifsteckWeb.Router do
  use APReifsteckWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :static do
    plug Plug.Static,
      at: "/media",
      from: "uploads"
  end

  scope "/", APReifsteckWeb do
    scope "/media" do
      pipe_through :static
      get("/*path", FallbackController, :not_found)
    end

    pipe_through :api

    resources "/users", UserController, only: [:index, :show, :new, :create]
    resources "/images", ImageController
  end
end
