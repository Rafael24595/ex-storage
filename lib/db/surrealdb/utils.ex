defmodule ExStorage.DB.SurrealDB.Utils do
  @moduledoc """
  Utility functions for transforming maps into filter strings
  compatible with SurrealDB queries.

  This module handles conversion of binary, numeric, and list
  values into filter expressions, including support for
  operators (`>`, `<`, `=`), wildcards (`*`), range (`-`), and negation (`!`).
  """

  alias ExStorage.Core.NumberUtils

  def map_to_filter(map) do
    filter =
      map
      |> Enum.reduce([], fn {k, v}, acc ->
        case field_to_filter(k, v) do
          nil ->
            acc

          result ->
            Enum.concat(acc, [result])
        end
      end)
      |> Enum.join(" AND ")

    if filter == "" do
      ""
    else
      "WHERE #{filter}"
    end
  end

  defp field_to_filter(key, value) when is_binary(value) do
    value = String.trim(value)

    {direction, value} =
      if String.starts_with?(value, "!") do
        {_, rest} = String.next_grapheme(value)
        {false, String.trim(rest)}
      else
        {true, value}
      end

    {direction, sentence} = string_to_filter(key, direction, value)

    direction_symbol = if direction, do: "", else: "NOT "
    "#{direction_symbol}#{sentence}"
  end

  defp field_to_filter(key, value) when is_number(value) do
    "#{key} = #{value}"
  end

  defp field_to_filter(_key, []), do: nil

  defp field_to_filter(key, value) when is_list(value) do
    list =
      Enum.map_join(value, ", ", fn
        v when is_binary(v) ->
          "\"#{v}\""

        v ->
          v
      end)

    "#{key} INSIDE [#{list}]"
  end

  defp field_to_filter(_key, _value), do: nil

  defp string_to_filter(key, direction, value) do
    case classify_pattern(value) do
      :contains ->
        value = String.slice(value, 1..-2//1)
        {direction, "#{key} CONTAINS \"#{value}\""}

      :ends_with ->
        value = String.slice(value, 1..-1//1)
        {direction, "#{key} ENDS WITH \"#{value}\""}

      :starts_with ->
        value = String.slice(value, 0..-2//1)
        {direction, "#{key} STARTS WITH \"#{value}\""}

      {:operator, operator, equals, value} ->
        equals_symbol = if equals, do: "=", else: ""
        {direction, "#{key} #{operator}#{equals_symbol} #{value}"}

      {:between, from, to} ->
        {direction, "#{key} >= #{from} AND #{key} <= #{to}"}

      :equals ->
        direction_symbol = if direction, do: "", else: "!"
        {true, "#{key} #{direction_symbol}= \"#{value}\""}
    end
  end

  defp classify_pattern(value) do
    cond do
      String.starts_with?(value, "*") and String.ends_with?(value, "*") ->
        :contains

      String.starts_with?(value, "*") ->
        :ends_with

      String.ends_with?(value, "*") ->
        :starts_with

      String.starts_with?(value, ">") or String.starts_with?(value, "<") ->
        classify_operator(value)

      String.match?(value, ~r/^-?\d+--?\d+$/) ->
        [option1, option2] = String.split(value, "-")
        {_, value1} = NumberUtils.integer_parse(option1, 0)
        {_, value2} = NumberUtils.integer_parse(option2, 0)
        {:between, value1, value2}

      true ->
        :equals
    end
  end

  defp classify_operator(value) do
    {operator, value} = String.next_grapheme(value)

    case String.next_grapheme(value) do
      {"=", value} ->
        {_, value} = NumberUtils.integer_parse(value, 0)
        {:operator, operator, true, value}

      _ ->
        {_, value} = NumberUtils.integer_parse(value, 0)
        {:operator, operator, false, value}
    end
  end
end
