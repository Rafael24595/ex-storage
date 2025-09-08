defmodule ExStorage.Domain.Utils do
  @moduledoc """
  Utility functions for converting field definitions and values into maps.

  This module is primarily used to transform a list of field definitions
  (with codes, types, and possible values) into a consistent map of
  `key => value` pairs, based on the provided input values.

  ## Supported field types

    * `"string"` — Direct value extraction
    * `"date"` — Direct value extraction
    * `"list"` — Direct value extraction
    * `"enum"` — Picks a single value from the `values` list based on cursor
    * `"tally"` — Picks multiple values from the `values` list based on indexes

  Fields with missing codes or invalid indexes are ignored.
  """

  def definition_to_map(definition, values) do
    definition
    |> Enum.reduce(%{}, fn d, acc ->
      case definition_to_field(d, values) do
        {nil, _} ->
          acc

        {_, nil} ->
          acc

        {key, value} ->
          Map.put(acc, key, value)
      end
    end)
  end

  defp definition_to_field(%{code: nil}, _values) do
    {nil, nil}
  end

  defp definition_to_field(%{code: key, type: "string"} = _field, values) do
    definition_value(key, values)
  end

  defp definition_to_field(%{code: key, type: "date"} = _field, values) do
    definition_value(key, values)
  end

  defp definition_to_field(%{code: key, type: "list"} = _field, values) do
    definition_value(key, values)
  end

  defp definition_to_field(%{code: _key, type: "enum", values: []} = _field, _values) do
    {nil, nil}
  end

  defp definition_to_field(%{code: key, type: "enum", values: items} = field, values) do
    value = Map.get(values, key, %{})

    case {Map.get(value, :cursor), Map.get(field, :required, false)} do
      {nil, true} ->
        value = Enum.at(items, 0)
        {key, value}

      {nil, _required} ->
        {nil, nil}

      {cursor, _required} when cursor < 0 ->
        {nil, nil}

      {cursor, _required} when cursor >= length(items) ->
        {nil, nil}

      {cursor, _required} ->
        value = Enum.at(items, cursor)
        {key, value}
    end
  end

  defp definition_to_field(%{code: key, type: "tally", values: items} = _field, values) do
    value =
      values
      |> Map.get(key, %{})
      |> Map.get(:value, [])
      |> Enum.reduce([], fn c, acc ->
        cond do
          c < 0 ->
            acc

          c >= length(items) ->
            acc

          true ->
            value = Enum.at(items, c)
            Enum.concat(acc, [value])
        end
      end)

    {key, value}
  end

  defp definition_value(key, values) do
    value =
      values
      |> Map.get(key, %{})
      |> Map.get(:value)

    {key, value}
  end
end
