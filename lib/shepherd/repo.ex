defmodule Shepherd.Repo do
  use Ecto.Repo,
    otp_app: :shepherd,
    adapter: Ecto.Adapters.Postgres
end
