defmodule APReifsteckWeb.Router do
  use APReifsteckWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
    plug APReifsteckWeb.APIAuthPlug, otp_app: :apreifsteck
  end

  pipeline :api_protected do
    plug Pow.Plug.RequireAuthenticated, error_handler: APReifsteckWeb.APIAuthErrorHandler
  end

  # Host the static images you can upload
  pipeline :static do
    plug :accepts, ["json"]

    plug Plug.Static,
      at: "/media",
      from: "uploads"
  end

  scope "/", APReifsteckWeb do
    # for static resources
    scope "/media" do
      pipe_through :static
      get("/*path", FallbackController, :not_found)
    end

    scope "/auth" do
      pipe_through :api

      resources "/registration", RegistrationController, singleton: true, only: [:create]
      resources "/session", SessionController, singleton: true, only: [:create, :delete]
      post "/session/renew", SessionController, :renew
    end

    scope "/users" do
      pipe_through :api
      get "/:uname", UserController, :show
    end

    scope "/posts" do
      pipe_through :api
      resources "/", PostController, only: [:index, :show]
      get "/user/:id", PostController, :index_by
      pipe_through :api_protected
      resources "/", PostController, except: [:index, :show, :edit, :new]
    end

    scope "/comments" do
      pipe_through :api
      resources "/", CommentController, only: [:show, :index]

      pipe_through :api_protected
      resources "/", CommentController, only: [:create, :update]
    end

    scope "/images" do
      pipe_through :api
      resources "/", ImageController, only: [:show, :index]

      pipe_through :api_protected
      resources "/", ImageController, only: [:update, :create, :delete]
    end
  end
end
