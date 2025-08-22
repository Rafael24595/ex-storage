defmodule ExStorage.TUI.Screens.ModalConfirm do
  @behaviour ExStorage.TUI.Screen

  def new_state(message, options, cursor \\ nil) do
    %{
       message: message,
       options: options,
       cursor: cursor || 0
     }
  end

  @impl true
  def onload(state) do
    render(state)
  end

  @impl true
  def render(state) do
    message = Map.get(state, :message)
    options = Map.get(state, :options)
    cursor = Map.get(state, :cursor, 0)

    formatter = fn
      {{k, d, _}, i} ->
        mark = if cursor == i, do: ">", else: " "
        " #{mark} #{d}(#{k})"

      {{k, _}, i} ->
        mark = if cursor == i, do: ">", else: " "
        " #{mark} #{k}"
    end

    keys =
      options
      |> Enum.with_index()
      |> Enum.map(formatter)

    mess_format = " #{message} "

    join = String.duplicate(" ", 9)
    keys_format = Enum.join(keys, join)
    keys_format = "  #{keys_format}  "

    max_len = max(String.length(mess_format), String.length(keys_format))

    mess_format = "|#{ExStorage.TUI.Screens.Formatter.center_text(mess_format, max_len)}|"
    keys_format = "|#{ExStorage.TUI.Screens.Formatter.center_text(keys_format, max_len)}|"

    limit = String.duplicate("-", String.length(mess_format))
    IO.puts(limit)
    IO.puts(mess_format)
    IO.puts(limit)
    IO.puts(keys_format)
    IO.puts("#{limit}\n")
  end

  @impl true
  def handle_event(state, :left) do
    cursor = Map.get(state, :cursor, 0)
    options = Map.get(state, :options)

    new_cursor =
      if cursor - 1 < 0 do
        length(options) - 1
      else
        cursor - 1
      end

    {:same, Map.put(state, :cursor, new_cursor)}
  end

  def handle_event(state, :right) do
    cursor = Map.get(state, :cursor, 0)
    options = Map.get(state, :options)

    new_cursor =
      if cursor + 1 > length(options) - 1 do
        0
      else
        cursor + 1
      end

    {:same, Map.put(state, :cursor, new_cursor)}
  end

  def handle_event(state, :enter) do
    cursor = Map.get(state, :cursor, 0)
    options = Map.get(state, :options)
    {_, _, func} = Enum.at(options, cursor)
    func.(state)
  end

  def handle_event(state, {:char, char}) do
    options = Map.get(state, :options)
    cursor = Enum.find_index(options, fn {c, _, _} -> c == char end)

    if cursor != nil do
      {_, _, func} = Enum.at(options, cursor)
      func.(state)
    else
      {:same, state}
    end
  end

  def handle_event(state, _) do
    {:keep, state}
  end
end
