defmodule APReifsteck.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      # Start the Ecto repository
      APReifsteck.Repo,
      {Phoenix.PubSub, [name: APReifsteck.PubSub, adapter: Phoenix.PubSub.PG2]},
      # Start the endpoint when the application starts
      APReifsteckWeb.Endpoint,
      # Starts a worker by calling: APReifsteck.Worker.start_link(arg)
      # {APReifsteck.Worker, arg},
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: APReifsteck.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    APReifsteckWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
