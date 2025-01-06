defmodule ExStorage.Repo do
  use Ecto.Repo,
    otp_app: :ex_storage,
    adapter: Ecto.Adapters.Postgres
end
