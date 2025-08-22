defmodule ExStorage.Domain.Work do

  #TODO: Redefine as atoms.
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
      title: work.title,
      type: work.type,
      creator: work.creator,
      released: work.released,
      concepts: work.concepts || []
    }
  end

  def definition() do
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
        code: "tags",
        title: "Tags",
        type: "list"
      },
      %{
        code: "type",
        title: "Type",
        type: "enum",
        values: @types
      }
    ]
  end
end
