defmodule ExStorage.TUI.Screen.WorkView do
  @behaviour ExStorage.TUI.Screen

  alias ExStorage.Core.Work.StateServer
  alias ExStorage.TUI.Screen.Modules

  def new_state() do
    %{
      show_help: false
    }
  end

  @impl true
  def onload(state) do
    render(state)
  end

  @impl true
  def render(%{show_help: true} = _state) do
    actions = [
      {"b", "Return to the works table."},
      {"r", "Refresh the page of the current work."},
      {"q", "Exit the application."}
    ]

    commands = [
      {"c", "continue"},
      {"b", "back"},
      {"q", "quit"}
    ]

    Modules.help(actions)
    Modules.commands(commands)
  end

  def render(_state) do
    work_state = StateServer.state()
    work = Enum.at(work_state.works, work_state.cursor)

    columns = [
      {"Title", [work.title]},
      {"Type", [work.type]},
      {"Released", [Integer.to_string(work.released)]},
      {"Creator", [work.creator]}
    ]

    header = "Source: #{work.id}"
    Modules.items_table(header, columns)

    commands = [
      {"h", "help"},
      {"b", "back"},
      {"r", "refresh"},
      {"q", "quit"}
    ]

    Modules.commands(commands)
  end

  @impl true
  def handle_event(%{show_help: false} = state, {:char, "h"}) do
    state = Map.put(state, :show_help, true)
    {:same, state}
  end

  def handle_event(%{show_help: true} = state, {:char, "c"}) do
    state = Map.put(state, :show_help, false)
    {:same, state}
  end

  def handle_event(_state, {:char, "b"}) do
    {ExStorage.TUI.Screen.WorkTable, ExStorage.TUI.Screen.WorkTable.new_state()}
  end

  def handle_event(%{show_help: false} = state, {:char, "r"}) do
    StateServer.load_page()
    {:same, state}
  end

  def handle_event(state, {:char, "q"}), do: {:quit, state}

  def handle_event(state, _) do
    {:same, state}
  end
end
