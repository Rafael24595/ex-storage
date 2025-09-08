defmodule ExStorage.Core.Work.State do
  @moduledoc """
  Represents the state of work browsing and filtering within the system.

  Keeps track of the current repository, applied filters, pagination (cursor, offset, limit),
  and the total count of available works.
  """

  @type repo_module :: module()

  defstruct repository: nil,
            works: [],
            filter: %{},
            cursor: 0,
            count: 0,
            count_filter: 0,
            offset: 0,
            limit: 0,
            last: 0

  @type t :: %__MODULE__{
          repository: repo_module(),
          works: list(ExStorage.Domain.Work.t()),
          filter: map(),
          cursor: integer(),
          count: integer(),
          count_filter: integer() | nil,
          offset: integer(),
          limit: integer(),
          last: integer()
        }

  def new_state(repository) do
    %ExStorage.Core.Work.State{
      repository: repository,
      works: [],
      filter: %{},
      count: 0,
      count_filter: nil,
      offset: 0,
      limit: 10,
      last: 0
    }
  end
end
