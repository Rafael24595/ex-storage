defmodule ExStorage.Core.Worker.ConceptService do
  @moduledoc """
  Service module for handling concept-related work items.
  This module implements the `Service` behaviour and provides
  functionality to fetch and manage concept work items from the repository.
  """

  alias ExStorage.Core.Worker.Service
  alias ExStorage.Domain.ConceptV1.Constants
  alias ExStorage.Domain.DefinitionUtils

  @behaviour Service

  @pid :concept_service

  def pid do
    @pid
  end

  def fetch(state, offset) do
    limit = Map.get(state, :limit, 10)

    filter_definition = Constants.filter_definition()
    filter_values = Map.get(state, :filter, %{})

    filter = DefinitionUtils.definition_to_map(filter_definition, filter_values)

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
