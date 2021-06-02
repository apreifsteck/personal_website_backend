# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :apreifsteck,
  namespace: APReifsteck,
  ecto_repos: [APReifsteck.Repo]

# Configures the endpoint
config :apreifsteck, APReifsteckWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "oqqZfoQ2L7Prw1Vy6StLjpEGDdNlWzaXRzwuR7YmjRkC4NJo7jOYJucJr2tWJc69",
  render_errors: [view: APReifsteckWeb.ErrorView, accepts: ~w(json)],
  pubsub_server: APReifsteck.PubSub,
  live_view: [signing_salt: "tuhgCOdu"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :apreifsteck, :pow,
  user: APReifsteck.Accounts.User,
  repo: APReifsteck.Repo

config :waffle,
  storage: Waffle.Storage.Local
  # asset_host: "http://static.example.com"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
