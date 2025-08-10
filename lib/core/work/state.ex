defmodule ExStorage.Core.Work.State do
  defstruct [
    works: [],
    cursor: 0,
    count: 0,
    offset: 0,
    limit: 0,
    last: 0,
  ]

  @type t :: %__MODULE__{
          works: list(ExStorage.Domain.Work.t()),
          cursor: integer() | nil,
          count: integer() | nil,
          offset: integer() | nil,
          limit: integer() | nil,
          last: integer() | nil
        }
end
