defmodule Monorepo.Repo do
  use Ecto.Repo,
    otp_app: :monorepo,
    adapter: Ecto.Adapters.Postgres
end
