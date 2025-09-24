defmodule ExStorage.Domain.WorkV1 do

  @version "v1"

  def version do
    @version
  end

  defstruct [
    :id,
    :version,
    :timestamp,
    :title,
    :category,
    :format,
    :status,
    :genre,
    :publisher,
    :direction,
    :cast,
    :music,
    :amount,
    :released,
    :aquired,
    :concepts,
    :tags,
    type: :other
  ]

  @type t :: %__MODULE__{
          id: String.t() | nil,
          version: String.t(),
          timestamp: integer(),
          title: String.t(),
          category: String.t(),
          format: String.t(),
          status: String.t(),
          genre: list(String.t()),
          publisher: String.t(),
          direction: list(String.t()),
          cast: list(String.t()),
          music: list(String.t()),
          amount: integer(),
          released: integer(),
          aquired: integer(),
          concepts: list(String.t()),
          tags: list(String.t())
        }

  def from_map(map) when is_map(map) do
    %__MODULE__{
      id: Map.get(map, "id"),
      version: Map.get(map, "version"),
      timestamp: Map.get(map, "timestamp"),
      title: Map.get(map, "title"),
      category: Map.get(map, "category"),
      format: Map.get(map, "format"),
      status: Map.get(map, "status"),
      genre: Map.get(map, "genre", []),
      publisher: Map.get(map, "publisher"),
      direction: Map.get(map, "direction", []),
      cast: Map.get(map, "cast", []),
      music: Map.get(map, "music", []),
      amount: Map.get(map, "amount"),
      released: Map.get(map, "released"),
      aquired: Map.get(map, "aquired"),
      concepts: Map.get(map, "concepts", []),
      tags: Map.get(map, "tags", [])
    }
  end

  def to_map(%__MODULE__{} = work) do
    %{
      id: work.id,
      version: work.version,
      timestamp: work.timestamp,
      title: work.title,
      category: work.category,
      format: work.format,
      status: work.status,
      genre: work.genre || [],
      publisher: work.publisher,
      direction: work.direction || [],
      cast: work.cast || [],
      music: work.music || [],
      amount: work.amount,
      released: work.released,
      aquired: work.aquired,
      concepts: work.concepts || [],
      tags: work.tags || []
    }
  end
end
