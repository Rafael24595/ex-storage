defmodule ExStorage.TUI.Screen.Home.Tables do
  @moduledoc """
  Home screen showing available tables.
  """

  alias ExStorage.Core.Utils
  alias ExStorage.Core.Worker.ConceptService
  alias ExStorage.Core.Worker.StateServer
  alias ExStorage.Core.Worker.WorkService
  alias ExStorage.TUI.Screen.Concept.Table, as: ConceptTable
  alias ExStorage.TUI.Screen.Constants
  alias ExStorage.TUI.Screen.Modules
  alias ExStorage.TUI.Screen.Work.Table, as: WorkTable


  @behaviour ExStorage.TUI.Screen

  @pid_work WorkService.pid()
  @pid_concept ConceptService.pid()

  @works_table %{title: "Works", module: WorkTable, state: WorkTable.new_state(), pid: @pid_work, count: 0}
  @concepts_table %{title: "Concepts", module: ConceptTable, state: ConceptTable.new_state(), pid: @pid_concept, count: 0}

  @tables [
    @works_table,
    @concepts_table
  ]

  def new_state do
    %{
      cursor: 0,
      show_help: false
    }
  end

  @impl true
  def onload(state) do
    StateServer.load_page(@pid_work)
    StateServer.load_page(@pid_concept)
    render(state)
  end

  @impl true
  def render(%{show_help: true} = _state) do
    custom_controls = [
      {"v", "Open a modal with the details of the selected table."},
      {"q", "Exit the application."}
    ]

    actions = Constants.items_table_help(nil, custom_controls)

    commands = [
      {"c", "continue"},
      {"q", "quit"}
    ]

    Modules.help(actions)
    Modules.commands(commands)
  end

  def render(state) do
    cursor = Map.get(state, :cursor, 0)

    work_state = StateServer.state(@pid_work)
    works = work_state.count

    concept_state = StateServer.state(@pid_concept)
    concepts = concept_state.count

    header =
      Modules.header_state(
        "Tables",
        length(@tables)
      )

    tables = [
      Map.put(@works_table, :count, works),
      Map.put(@concepts_table, :count, concepts)
    ]

    formatter = tables_formatter(cursor)
    Modules.items_list(header, tables, formatter)

    commands = [
      {"h", "help"},
      {"r", "refresh"},
      {"v", "view"},
      {"q", "quit"}
    ]

    Modules.commands(commands)
  end

  @impl true
  def handle_event(%{show_help: false} = state, :up) do
    new_cursor = Utils.decrease_cursor(state.cursor, @tables)
    new_state = Map.put(state, :cursor, new_cursor)
    {:same, new_state}
  end

  def handle_event(%{show_help: false} = state, :down) do
    new_cursor = Utils.increase_cursor(state.cursor, @tables)
    new_state = Map.put(state, :cursor, new_cursor)
    {:same, new_state}
  end

  def handle_event(%{show_help: false} = state, {:char, "h"}) do
    state = Map.put(state, :show_help, true)
    {:same, state}
  end

  def handle_event(%{show_help: false} = state, {:char, "v"}) do
    cursor = Map.get(state, :cursor, 0)
    table = Enum.at(@tables, cursor)

    if table == nil do
      {:same, state}
    else
      {table.module, table.state}
    end
  end

  def handle_event(state, {:char, "q"}), do: {:quit, state}

  def handle_event(%{show_help: false} = state, {:char, text}) do
    if String.match?(text, ~r/^\d+$/) do
      new_cursor = String.to_integer(text)
      new_cursor = Utils.define_cursor(new_cursor, @tables)
      new_state = Map.put(state, :cursor, new_cursor)
      {:same, new_state}
    else
      {:same, state}
    end
  end

  def handle_event(state, _) do
    {:same, state}
  end

  defp tables_formatter(cursor) do
    fn {table, idx} ->
      title = table.title || "(untitled)"
      count = table.count || 0
      marker = if idx == cursor, do: "›", else: " "
      "#{marker} #{idx}.- #{title} (#{count})"
    end
  end
end
