defmodule ExStorage.TUI.Screens.Utils do

   def print_sources_list(header, rows, formatter) do
    header = " #{header} "

    rows = Enum.with_index(rows)
    |> Enum.map(formatter)

    header_len = String.length(header)
    max_len =
      rows
      |> Enum.map(&String.length/1)
      |> Enum.max()

    max_len = max(max_len, header_len)

    header_limit = String.duplicate("-", header_len)
    limit = String.duplicate("-", max_len)

    IO.puts(header_limit)
    IO.puts(header)
    IO.puts(limit)

    Enum.each(rows, fn r -> IO.puts(r) end)
  end

  def print_source_table(id, columns) do
    source = "| Source: #{id} |"
    source_limit = String.duplicate("-", String.length(source))

    {:headers, headers, :rows, rows} = ExStorage.TUI.Screens.Formatter.format_table(columns)

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

  def print_commands(commands) do
    header = "[ Commands ] "
    commands = Enum.reduce(commands, "", fn
      {k, d}, acc -> acc <> "#{k}=#{d} "
      {k}, acc -> acc <> "#{k}  "
    end)

    fix_len = max(String.length(commands) - String.length(header), 3)
    fix = String.duplicate("=", fix_len)
    header = "#{header}#{fix}"

    IO.puts("\n#{header}")
    IO.puts(commands)
  end
end
