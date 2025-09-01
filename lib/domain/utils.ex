defmodule ExStorage.Domain.Utils do
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

  defp definition_to_field(%{code: key, type: "enum", values: items} = _field, values) do
    value = Map.get(values, key, %{})

    case Map.get(value, :cursor) do
      cursor when cursor == nil ->
        {nil, nil}

      cursor when cursor < 0 ->
        {nil, nil}

      cursor when cursor >= length(items) ->
        {nil, nil}

      cursor ->
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
