defmodule ExStorage.TUI.Screens.WorkView do
  @behaviour ExStorage.TUI.Screen

  @impl true
  def onload(state) do
    render(state)
  end

  @impl true
  def render(_state) do
    work_state = ExStorage.Core.Work.StateServer.state()
    work = Enum.at(work_state.works, work_state.cursor)

    columns = [
      {"Title", [work.title]},
      {"Type", [work.type]},
      {"Released", [Integer.to_string(work.released)]},
      {"Creator", [work.creator]}
    ]

    print_source_table(work.id, columns)

    commands = [
      {"b", "back"},
      {"r", "refresh"},
      {"q", "quit"},
    ]

    ExStorage.TUI.Screens.Modules.commands(commands)
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

  @impl true
  def handle_event(_state, {:char, "b"}) do
    {ExStorage.TUI.Screens.WorkTable, %{}}
  end

  def handle_event(state, {:char, "r"}) do
    ExStorage.Core.Work.StateServer.load_page()
    {:same, state}
  end

  def handle_event(state, {:char, "q"}), do: {:quit, state}

  def handle_event(state, _) do
    {:keep, state}
  end
end
