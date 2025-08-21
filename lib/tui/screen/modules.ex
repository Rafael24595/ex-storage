defmodule ExStorage.TUI.Screens.Modules do
  def commands(commands) do
    header = "[ Commands ] "

    commands =
      Enum.map_join(commands, " ", fn
        {k, d, _f} -> "#{d}(#{k})"
        {k, d} -> "#{d}(#{k})"
        k -> "#{k} "
      end)

    fix_len = max(String.length(commands) - String.length(header), 3)
    fix = String.duplicate("=", fix_len)
    header = "#{header}#{fix}"

    IO.puts("\n#{header}")
    IO.puts("#{commands}\n")
  end
end
