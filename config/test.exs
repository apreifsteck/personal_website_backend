use Mix.Config

# Configure your database
config :apreifsteck, APReifsteck.Repo,
  username: "postgres",
  password: "postgres",
  database: "apreifsteck_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :apreifsteck, APReifsteckWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn
config :pbkdf2_elixir, :rounds, 1
config :pow, Pow.Ecto.Schema.Password, iterations: 1
