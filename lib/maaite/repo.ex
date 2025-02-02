defmodule Maaite.Repo do
  use Ecto.Repo,
    otp_app: :maaite,
    adapter: Ecto.Adapters.SQLite3
end
