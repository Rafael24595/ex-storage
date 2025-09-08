defmodule ExStorage.Domain.Work do
  @moduledoc """
  Represents a creative work (e.g., novel, film, videogame) in the ExStorage domain.
  Provides struct definition, serialization helpers, and metadata for forms and filters.
  """

  @types ["novel", "film", "videogame", "other"]

  @enforce_keys [:title, :type]
  defstruct [
    :id,
    :title,
    :creator,
    :released,
    :concepts,
    type: :other
  ]

  @type t :: %__MODULE__{
          id: String.t() | nil,
          title: String.t(),
          type: String.t(),
          creator: String.t() | nil,
          released: integer() | nil,
          concepts: list(String.t())
        }

  def from_map(map) when is_map(map) do
    %__MODULE__{
      id: Map.get(map, "id"),
      title: Map.get(map, "title"),
      type: Map.get(map, "type"),
      creator: Map.get(map, "creator"),
      released: Map.get(map, "released"),
      concepts: Map.get(map, "concepts", [])
    }
  end

  def to_map(%__MODULE__{} = work) do
    %{
      id: work.id,
      title: work.title,
      type: work.type,
      creator: work.creator,
      released: work.released,
      concepts: work.concepts || []
    }
  end

  def types do
    @types
  end

  def insert_definition do
    [
      %{
        code: "title",
        title: "Title",
        type: "string"
      },
      %{
        code: "creator",
        title: "Creator",
        type: "string"
      },
      %{
        code: "released",
        title: "Released",
        type: "date"
      },
      %{
        code: "tags",
        title: "Tags",
        type: "list"
      },
      %{
        code: "type",
        title: "Type",
        type: "enum",
        values: types(),
        required: true
      },
      %{
        code: "concepts",
        title: "Concepts",
        type: "tally",
        values: ["condept_001", "condept_002", "condept_003", "condept_004"]
      }
    ]
  end

  def filter_definition do
    [
      %{
        code: "id",
        title: "Id",
        type: "string"
      },
      %{
        code: "title",
        title: "Title",
        type: "string"
      },
      %{
        code: "creator",
        title: "Creator",
        type: "string"
      },
      %{
        code: "released_from",
        title: "Released From",
        type: "date"
      },
      %{
        code: "released_to",
        title: "Released To",
        type: "date"
      },
      %{
        code: "tags",
        title: "Tags",
        type: "list"
      },
      %{
        code: "type",
        title: "Type",
        type: "enum",
        values: types()
      },
      %{
        code: "concepts",
        title: "Concepts",
        type: "tally",
        values: ["condept_001", "condept_002", "condept_003", "condept_004"]
      }
    ]
  end
end
