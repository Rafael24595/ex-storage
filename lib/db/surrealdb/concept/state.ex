defmodule ExStorage.DB.SurrealDB.ConceptState do
  @moduledoc false
  
  alias ExStorage.DB.SurrealDB.Connection

  defstruct [
    :conn
  ]

  @type t :: %__MODULE__{
          conn: Connection.t()
        }

  def new_connection(conn) do
    %ExStorage.DB.SurrealDB.ConceptState{
      conn: conn
    }
  end
end
