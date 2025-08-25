defmodule ExStorage.Domain.Concept do

  @enforce_keys [:name]
  defstruct [
    :id,
    :name,
    :description
  ]

  @type t :: %__MODULE__{
          id: String.t() | nil,
          name: String.t(),
          description: String.t() | nil
        }

  def from_map(map) when is_map(map) do
    %__MODULE__{
      id: Map.get(map, "id"),
      name: Map.get(map, "name"),
      description: Map.get(map, "description")
    }
  end

  def to_map(%__MODULE__{} = concept) do
    %{
      name: concept.name,
      description: concept.description
    }
  end
end
