defmodule ExStorage.TUI.Screen.Concept.View do
  @moduledoc """
  TUI screen for viewing and managing a single concept data.
  """

  @behaviour ExStorage.TUI.Screen

  alias ExStorage.Core.Worker.ConceptService
  alias ExStorage.Core.Worker.StateServer
  alias ExStorage.Domain.ConceptV1.Factory
  alias ExStorage.TUI.Screen.Concept.Table
  alias ExStorage.TUI.Screen.Modules

  @pid ConceptService.pid()

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
      {"b", "Return to the concepts table."},
      {"r", "Refresh the page of the current concept."},
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
    concept_state = StateServer.state(@pid)
    concept = Enum.at(concept_state.items, concept_state.cursor)

    columns = Factory.to_columns(concept)
    header = "Source: #{concept.id}"
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
    {Table, Table.new_state()}
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
