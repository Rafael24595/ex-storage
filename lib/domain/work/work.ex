defmodule ExStorage.Domain.Work do
  @moduledoc """
  Represents a creative work (e.g., novel, film, videogame) in the ExStorage domain.
  Provides struct definition, serialization helpers, and metadata for forms and filters.
  """
  alias ExStorage.Domain.Work.Constants
  alias ExStorage.Core.DateUtils
  alias ExStorage.Core.NumberUtils

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

  def to_columns(works) when is_list(works) do
    [
      {"Title",
       works
       |> Enum.map(& &1.title)},
      {"Type",
       works
       |> Enum.map(& &1.type)},
      {"Released",
       works
       |> Enum.map(&DateUtils.from_millis(&1.released))},
      {"Creator",
       works
       |> Enum.map(& &1.creator)}
    ]
  end

  def to_columns(work) do
    to_columns([work])
  end

  def fix_filter_map(filter) do
    filter
    |> fix_released_filter()
    |> remove_invalid_keys()
  end

  defp fix_released_filter(filter) do
    filter =
      case {Map.get(filter, "released_from"), Map.get(filter, "released_to")} do
        {nil, nil} ->
          filter

        {from, nil} ->
          {_, from_int} = NumberUtils.integer_parse(from, nil)
          Map.put(filter, "released", from_int)

        {nil, to} ->
          {_, to_int} = NumberUtils.integer_parse(to, nil)
          Map.put(filter, "released", to_int)

        {from, to} ->
          {_, from_int} = NumberUtils.integer_parse(from, nil)
          {_, to_int} = NumberUtils.integer_parse(to, nil)
          released = if from_int != nil && to_int != nil, do: "#{from_int}-#{to_int}", else: nil
          Map.put(filter, "released", released)
      end

    filter
    |> Map.delete("released_from")
    |> Map.delete("released_to")
  end

  defp remove_invalid_keys(filter) do
    format_items = []
    valid_codes =
      Constants.insert_definition([format_items])
      |> Enum.map(& &1.code)

    Map.take(filter, valid_codes)
  end
end
