defmodule APReifsteck.Repo do
  use Ecto.Repo,
    otp_app: :apreifsteck,
    adapter: Ecto.Adapters.Postgres
end
