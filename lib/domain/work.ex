defmodule ExStorage.Domain.Work do
  @type work_type :: :novel | :movie | :game | :other

  @enforce_keys [:title, :type]
  defstruct [
    :id,
    :title,
    :creator,
    :released,
    :concepts,
    :based_on,
    type: :other
  ]

  @type t :: %__MODULE__{
          id: String.t() | nil,
          title: String.t(),
          type: String.t(),
          creator: String.t() | nil,
          released: integer() | nil,
          concepts: list(String.t()),
          based_on: list(String.t())
        }

  def from_map(map) when is_map(map) do
    %__MODULE__{
      id: Map.get(map, "id"),
      title: Map.get(map, "title"),
      type: Map.get(map, "type"),
      creator: Map.get(map, "creator"),
      released: Map.get(map, "released"),
      concepts: Map.get(map, "concepts", []),
      based_on: Map.get(map, "based_on", [])
    }
  end

  def to_map(%__MODULE__{} = work) do
    %{
      title: work.title,
      type: work.type,
      creator: work.creator,
      released: work.released,
      concepts: work.concepts || [],
      based_on: work.based_on || []
    }
  end
end
