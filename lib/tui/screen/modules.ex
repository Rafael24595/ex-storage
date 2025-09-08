defmodule ExStorage.TUI.Screen.Modules do
  @moduledoc """
  Provides terminal UI rendering helpers for displaying
  help text, commands, lists, and tables...
  """

  alias ExStorage.Core.ListUtils
  alias ExStorage.TUI.Screen.Formatter

  def help(actions) do
    max_len =
      actions
      |> Enum.map(fn
        {c, _d} -> String.length(c)
        t -> String.length(t)
      end)
      |> Enum.max()

    {rows, _} =
      actions
      |> Enum.with_index()
      |> Enum.reduce({[], 0}, fn
        {{c, d}, _idx}, {acc, pad} ->
          lead = String.duplicate(" ", 1 + pad)
          fix = max(max_len - pad, 0)
          row = "#{lead}#{String.pad_trailing(c, fix)} : #{d}"
          {acc ++ [row], pad}

        {"\n" = t, _idx}, {acc, pad} when is_binary(t) ->
          new_pad = max(pad - 1, 0)

          new_acc = if pad == 0, do: acc ++ [t], else: acc

          {new_acc, new_pad}

        {t, idx}, {acc, pad} when is_binary(t) ->
          jump = if idx != 0, do: "\n", else: ""

          lead = String.duplicate(" ", 1 + pad)
          row = "#{lead}#{jump}#{t}"
          {acc ++ [row], pad + 1}

        _, {acc, pad} ->
          {acc, pad}
      end)

    head_len =
      rows
      |> Enum.map(&String.length/1)
      |> Enum.max()

    header = String.pad_trailing("= Help ", head_len, "=")

    IO.puts("#{header}\n")
    Enum.each(rows, fn r -> IO.puts(r) end)
  end

  def commands(commands) do
    header = "[ Commands ] "

    rows =
      commands
      |> ListUtils.chunk_by("\n")
      |> Enum.map(fn r ->
        Enum.map_join(r, " ", fn
          {k, d, _f} -> "#{d}(#{k})"
          {k, d} -> "#{d}(#{k})"
          k -> "#{k} "
        end)
      end)

    max_len =
      rows
      |> Enum.map(&String.length/1)
      |> Enum.max(fn -> 0 end)

    header = String.pad_trailing(header, max_len, "=")

    IO.puts("\n#{header}")

    Enum.each(rows, fn r ->
      IO.puts(r)
    end)

    IO.puts("")
  end

  def header_state(title, count, count_filter, from, to) do
    %{
      title: title,
      count: count,
      count_filter: count_filter,
      from: from,
      to: to
    }
  end

  def items_list(%{title: title, count: count, count_filter: count_filter, from: from, to: to}, rows, formatter) do
    filter = if count_filter == nil do
      ""
    else
      "#{count_filter}/"
    end
    header = " #{title} (#{filter}#{count}) [#{from} - #{to}] "

    rows =
      Enum.with_index(rows)
      |> Enum.map(formatter)

    header_len = String.length(header)

    max_len =
      rows
      |> Enum.map(&String.length/1)
      |> Enum.max(fn -> 0 end)

    max_len = max(max_len, header_len)

    header_limit = String.duplicate("-", header_len)
    limit = String.duplicate("-", max_len)

    IO.puts(header_limit)
    IO.puts(header)
    IO.puts(limit)

    if Enum.empty?(rows) do
      IO.puts("- No items found -")
    else
      Enum.each(rows, fn r -> IO.puts(r) end)
    end
  end

  def items_table(header, columns) do
    source = "| #{header} |"
    source_limit = String.duplicate("-", String.length(source))

    {:headers, headers, :rows, rows} = Formatter.format_table(columns)

    limit = String.duplicate("-", String.length(headers))
    IO.puts(source_limit)
    IO.puts(source)
    IO.puts(limit)
    IO.puts(headers)

    Enum.each(rows, fn r ->
      IO.puts(limit)
      IO.puts(r)
    end)

    IO.puts(limit)
  end
end
