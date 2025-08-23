defmodule ExStorage.TUI.Screens.Modules do
  def help(actions) do
    max_len =
      actions
      |> Enum.map(fn {c, _d} -> String.length(c) end)
      |> Enum.max()

    rows =
      actions
      |> Enum.map(fn {c, d} ->
        " #{String.pad_trailing(c, max_len)} : #{d}"
      end)

    head_len =
      rows
      |> Enum.map(&String.length/1)
      |> Enum.max()

    header = String.pad_trailing("= Help ", head_len, "=")


    IO.puts("#{header}\n")
    Enum.each(rows, fn r ->IO.puts(r)  end)
  end

  def commands(commands) do
    header = "[ Commands ] "

    commands =
      Enum.map_join(commands, " ", fn
        {k, d, _f} -> "#{d}(#{k})"
        {k, d} -> "#{d}(#{k})"
        k -> "#{k} "
      end)

    header = String.pad_trailing(header, String.length(commands), "=")

    IO.puts("\n#{header}")
    IO.puts("#{commands}\n")
  end
end
