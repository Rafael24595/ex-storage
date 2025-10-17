defmodule ExStorage.Core.Utils do
  @moduledoc false

  def decrease_cursor(cursor, options) do
    cursor = cursor || 0
    options = options || []

    if cursor - 1 < 0 do
      length(options) - 1
    else
      cursor - 1
    end
  end

  def increase_cursor(cursor, options) do
    cursor = cursor || -1
    options = options || []

    if cursor + 1 > length(options) - 1 do
      0
    else
      cursor + 1
    end
  end

  def define_cursor(cursor, options) do
    total = length(options)

    cursor
    |> max(0)
    |> min(max(total - 1, 0))
  end

  def equal_ignore_case?(a, b) do
    String.downcase(a) == String.downcase(b)
  end

  def pattern_to_regex(pattern) do
    rest =
      pattern
      |> String.trim()
      |> String.downcase()
      |> Regex.escape()
      |> String.replace("\\*", ".*")

    case Regex.compile("^#{rest}$") do
      {:ok, regex} ->
        regex

      {:error, reason} ->
        Log.error("Invalid regex pattern: #{pattern}. Reason: #{inspect(reason)}")
        ~r/^$/
    end
  end

  def match_index(list, pattern, extractor) do
    if String.contains?(pattern, "*") do
      regex = pattern_to_regex(pattern)

      Enum.find_index(list, fn i ->
        v = extractor.(i)
        Regex.match?(regex, String.downcase(v))
      end)
    else
      Enum.find_index(list, fn i ->
        v = extractor.(i)
        equal_ignore_case?(v, pattern)
      end)
    end
  end

  def clean_pointers(list, items) do
    len = length(items) - 1

    list
    |> Enum.filter(fn c ->
      c >= 0 && c <= len
    end)
    |> Enum.uniq()
  end

  def parse_basic_command(text) do
    fragments =
      text
      |> String.trim()
      |> String.split(" ", parts: 2)

    case fragments do
      [cmd, arg] -> {:cmd, cmd, arg}
      [text] -> {:text, text}
    end
  end

  def parse_slash_command("") do
    {:text, ""}
  end

  def parse_slash_command("\\") do
    {:text, ""}
  end

  def parse_slash_command(text) do
    {first, rest} =
      text
      |> String.trim()
      |> String.next_grapheme()

    rest = String.trim(rest)

    case first do
      "\\" ->
        {cmd, rest} = String.next_grapheme(rest)
        rest = String.trim(rest)
        {:cmd, cmd, rest}

      _ ->
        {:text, text}
    end
  end
end
