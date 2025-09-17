defmodule ExStorage.Core.Worker.WorkService do
  alias ExStorage.Core.Worker.Service
  alias ExStorage.Domain.Utils, as: DomainUtils
  alias ExStorage.Domain.Work, as: DomainWork

  @behaviour Service

  def fetch(state, offset) do
    limit = Map.get(state, :limit, 10)

    filter_definition = DomainWork.filter_definition()
    filter_values = Map.get(state, :filter, %{})

    filter = DomainUtils.definition_to_map(filter_definition, filter_values)
    filter = DomainWork.fix_filter_map(filter)

    with {:ok, works} <- state.repository.find(limit, offset, filter),
         {:ok, count} <- state.repository.count(),
         {:ok, count_filter} <- state.repository.count_filter(filter) do
      sum = min(count_filter || count, count)
      offset = min(offset, sum)

      if offset == sum do
        {:ok, state}
      else
        last = min(offset + limit, sum)

        new_state =
          state
          |> Map.put(:items, works)
          |> Map.put(:cursor, 0)
          |> Map.put(:count, count)
          |> Map.put(:offset, offset)
          |> Map.put(:last, last)
          |> Map.put(:count_filter, count_filter)

        {:ok, new_state}
      end
    else
      {:error, reason} ->
        {:error, state, reason}
    end
  end
end
