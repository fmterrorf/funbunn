defmodule Funbunn.Repo do
  use Ecto.Repo,
    otp_app: :funbunn,
    adapter: Ecto.Adapters.Postgres
end
