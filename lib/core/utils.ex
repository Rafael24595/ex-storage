defmodule ExStorage.Core.Utils do
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

    Regex.compile!("^#{rest}$")
  end

  def match_index(list, pattern, extractor) do
    try do
      cond do
        String.contains?(pattern, "*") ->
          regex = pattern_to_regex(pattern)

          Enum.find_index(list, fn i ->
            v = extractor.(i)
            Regex.match?(regex, String.downcase(v))
          end)

        true ->
          Enum.find_index(list, fn i ->
            v = extractor.(i)
            equal_ignore_case?(v, pattern)
          end)
      end
    rescue
      err ->
        Log.error("An error occurred while regex matching. Actual value: #{pattern}", err)
        nil
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
