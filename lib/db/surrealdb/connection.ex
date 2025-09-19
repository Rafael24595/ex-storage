defmodule ExStorage.DB.SurrealDB.Connection do

  @default_url "http://127.0.0.1:8000/rpc"
  @default_user "root"
  @default_pass "root"

  defstruct [
    :url,
    :user,
    :pass,
    :ns,
    :db,
  ]

  @type t :: %__MODULE__{
    url: String.t(),
    user: String.t(),
    pass: String.t(),
    ns: String.t(),
    db: String.t(),
  }

  def new_connection(ns, db) do
    url = System.get_env("SURREAL_URL") || @default_url
    user = System.get_env("SURREAL_USER") || @default_user
    pass = System.get_env("SURREAL_PASS") || @default_pass

    %ExStorage.DB.SurrealDB.Connection{
      url: url,
      user: user,
      pass: pass,
      ns: ns,
      db: db
    }
  end
end
