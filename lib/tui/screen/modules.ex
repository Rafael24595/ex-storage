defmodule ExStorage.TUI.Screens.Modules do
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
