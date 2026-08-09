defmodule Finsave.Repo do
  use Ecto.Repo,
    otp_app: :finsave,
    adapter: Ecto.Adapters.Postgres
end
