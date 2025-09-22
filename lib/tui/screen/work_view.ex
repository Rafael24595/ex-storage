defmodule ExStorage.TUI.Screen.WorkView do
  @behaviour ExStorage.TUI.Screen

  alias ExStorage.Core.Worker.StateServer
  alias ExStorage.Core.Worker.WorkService
  alias ExStorage.Domain.Work
  alias ExStorage.TUI.Screen.Modules
  alias ExStorage.TUI.Screen.WorkTable

  @pid WorkService.pid()

  def new_state do
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
    work_state = StateServer.state(@pid)
    work = Enum.at(work_state.items, work_state.cursor)

    columns = Work.to_columns(work)
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
    {WorkTable, WorkTable.new_state()}
  end

  def handle_event(%{show_help: false} = state, {:char, "r"}) do
    StateServer.load_page(@pid)
    {:same, state}
  end

  def handle_event(state, {:char, "q"}), do: {:quit, state}

  def handle_event(state, _) do
    {:same, state}
  end
end
