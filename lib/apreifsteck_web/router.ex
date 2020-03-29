defmodule APReifseckWeb.Router do
  use APReifseckWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", APReifseckWeb do
    pipe_through :api

    resources "/users", UserController, only: [:index, :show, :new, :create]
    resources "/images", ImageController
  end
end
