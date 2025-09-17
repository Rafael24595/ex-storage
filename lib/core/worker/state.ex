defmodule ExStorage.Core.Worker.State do
  @type repository :: module()
  @type service :: module()

  defstruct service: nil,
            repository: nil,
            items: [],
            filter: %{},
            cursor: 0,
            count: 0,
            count_filter: 0,
            offset: 0,
            limit: 0,
            last: 0

  @type t :: %__MODULE__{
          service: service(),
          repository: repository(),
          items: list(),
          filter: map(),
          cursor: integer(),
          count: integer(),
          count_filter: integer() | nil,
          offset: integer(),
          limit: integer(),
          last: integer()
        }

  def new_state(service, repository) do
    %ExStorage.Core.Worker.State{
      service: service,
      repository: repository,
      items: [],
      filter: %{},
      count: 0,
      count_filter: nil,
      offset: 0,
      limit: 10,
      last: 0
    }
  end
end
