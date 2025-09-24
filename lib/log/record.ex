defmodule ExStorage.Log.Record do
  @enforce_keys [:session_id, :category, :message, :timestamp]
  defstruct [
    :session_id,
    :category,
    :message,
    :references,
    :timestamp
  ]

  @type t :: %__MODULE__{
          session_id: String.t(),
          category: String.t(),
          message: String.t(),
          references: list(String.t()),
          timestamp: integer()
        }

  def from_map(map) when is_map(map) do
    %__MODULE__{
      session_id: Map.get(map, "session_id"),
      category: Map.get(map, "category"),
      message: Map.get(map, "message"),
      references: Map.get(map, "references"),
      timestamp: Map.get(map, "timestamp")
    }
  end

  def to_map(%__MODULE__{} = record) do
    %{
      session_id: record.session_id,
      category: record.category,
      message: record.message,
      references: record.references,
      timestamp: record.timestamp
    }
  end
end
