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

    ExStorage.TUI.Screens.Utils.print_source_table(work.id, columns)

    commands = [
      {"b", "back"},
      {"r", "refresh"},
      {"q", "quit"},
    ]

    ExStorage.TUI.Screens.Utils.print_commands(commands)
  end

  @impl true
  def handle_event(state, :up) do
    ExStorage.Core.Work.StateServer.decrement_cursor()
    {:same, state}
  end

  def handle_event(state, :down) do
    ExStorage.Core.Work.StateServer.increment_cursor()
    {:same, state}
  end

  def handle_event(state, :left) do
    case ExStorage.Core.Work.StateServer.prev() do
      {:same, _} ->
        {:keep, state}

      {:ok, _} ->
        {:same, state}
    end
  end

  def handle_event(state, :right) do
    case ExStorage.Core.Work.StateServer.next() do
      {:same, _} ->
        {:keep, state}

      {:ok, _} ->
        {:same, state}
    end

    {:same, state}
  end

  def handle_event(_state, {:char, "b"}) do
    {ExStorage.TUI.Screens.WorkTable, %{}}
  end

  def handle_event(state, {:char, "r"}) do
    ExStorage.Core.Work.StateServer.refresh()
    {:same, state}
  end

  def handle_event(state, {:char, "q"}), do: {:quit, state}

  def handle_event(state, _) do
    {:keep, state}
  end
end
