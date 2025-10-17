defmodule ExStorage.DB.SurrealDB.WorkState do
  @moduledoc false
  
  alias ExStorage.DB.SurrealDB.Connection

  defstruct [
    :conn
  ]

  @type t :: %__MODULE__{
          conn: Connection.t()
        }

  def new_connection(conn) do
    %ExStorage.DB.SurrealDB.WorkState{
      conn: conn
    }
  end
end
