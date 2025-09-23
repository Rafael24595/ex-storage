defmodule ExStorage.Domain.FilterUtils do
alias ExStorage.Core.NumberUtils

  def fix_date_filter(filter, from_key, to_key, target_key) do
    filter =
      case {Map.get(filter, from_key), Map.get(filter, to_key)} do
        {nil, nil} ->
          filter

        {from, nil} ->
          {_, from_int} = NumberUtils.integer_parse(from, nil)
          Map.put(filter, target_key, from_int)

        {nil, to} ->
          {_, to_int} = NumberUtils.integer_parse(to, nil)
          Map.put(filter, target_key, to_int)

        {from, to} ->
          {_, from_int} = NumberUtils.integer_parse(from, nil)
          {_, to_int} = NumberUtils.integer_parse(to, nil)
          released = if from_int != nil && to_int != nil, do: "#{from_int}-#{to_int}", else: nil
          Map.put(filter, target_key, released)
      end

    filter
    |> Map.delete(from_key)
    |> Map.delete(to_key)
  end

  def remove_invalid_keys(filter, definition) do
    valid_codes =
      definition
      |> Enum.map(& &1.code)

    Map.take(filter, valid_codes)
  end
end
