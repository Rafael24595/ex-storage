defmodule ExStorage.Log.Record do
  @enforce_keys [:session_id, :category, :message, :timestamp]
  defstruct [
    :session_id,
    :category,
    :message,
    :timestamp
  ]

  @type t :: %__MODULE__{
          session_id: String.t(),
          category: String.t(),
          message: String.t(),
          timestamp: integer()
        }

  def from_map(map) when is_map(map) do
    %__MODULE__{
      session_id: Map.get(map, "session_id"),
      category: Map.get(map, "category"),
      message: Map.get(map, "message"),
      timestamp: Map.get(map, "timestamp")
    }
  end

  def to_map(%__MODULE__{} = record) do
    %{
      category: record.category,
      message: record.message,
      timestamp: record.timestamp
    }
  end
end
