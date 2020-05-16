defmodule APReifsteckWeb.Router do
  use APReifsteckWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
    # TODO create this.
    plug APReifsteckWeb.APIAuthPlug, otp_app: :apreifsteck
  end

  pipeline :api_protected do
    # TODO create this.
    plug Pow.Plug.RequireAuthenticated, error_handler: APReifsteckWeb.APIAuthErrorHandler
  end

  # Host the static images you can upload
  pipeline :static do
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

    pipe_through [:api, :api_protected]

    resources "/users", UserController, only: [:index, :show, :update, :create, :delete]
    resources "/posts", PostController, except: [:new, :edit]
    # TODO: add other image routes
    delete "/images", ImageController, :delete
  end
end
