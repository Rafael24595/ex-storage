defmodule ExStorage.Domain.ConceptV1 do

  @version "v1"

  def version do
    @version
  end

  defstruct [
    :id,
    :version,
    :timestamp,
    :concept,
    :description
  ]

  @type t :: %__MODULE__{
          id: String.t() | nil,
          version: String.t(),
          timestamp: integer(),
          concept: String.t(),
          description: String.t()
        }

  def from_map(map) when is_map(map) do
    %__MODULE__{
      id: Map.get(map, "id"),
      version: Map.get(map, "version"),
      timestamp: Map.get(map, "timestamp"),
      concept: Map.get(map, "concept"),
      description: Map.get(map, "description")
    }
  end

  def to_map(%__MODULE__{} = concept) do
    %{
      id: concept.id,
      version: concept.version,
      timestamp: concept.timestamp,
      concept: concept.concept,
      description: concept.description
    }
  end
end
