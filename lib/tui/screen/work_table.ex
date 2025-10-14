defmodule ExStorage.TUI.Screen.WorkTable do
  @moduledoc """
  TUI screen for listing, navigating, and managing works.

  This screen implements the `ExStorage.TUI.Screen` behaviour and acts as
  the main interface for interacting with work entities
  through the terminal.

  ## State

  The screen’s state includes:

    * `:show_help` — toggles whether the help overlay is displayed.
  """

  @behaviour ExStorage.TUI.Screen

  alias ExStorage.Core.NumberUtils
  alias ExStorage.Core.Utils, as: CoreUtils
  alias ExStorage.Core.Worker.StateServer
  alias ExStorage.Core.Worker.WorkService
  alias ExStorage.Core.Worker.WorkTools
  alias ExStorage.Domain.{DefinitionUtils, WorkV1}
  alias ExStorage.TUI.Screen.Constants
  alias ExStorage.TUI.Screen.ModalConfirm
  alias ExStorage.TUI.Screen.ModalForm
  alias ExStorage.TUI.Screen.Modules
  alias ExStorage.TUI.Screen.WorkView

  @pid WorkService.pid()

  def new_state do
    %{
      show_help: false
    }
  end

  @impl true
  def onload(state) do
    StateServer.load_page(@pid)
    render(state)
  end

  @impl true
  def render(%{show_help: true} = _state) do
    custom_controls = [
      {"r", "Refresh the current page."},
      {"v", "Open a modal with the details of the selected work."},
      {"l number",
       "Set the number of items per page. If no value is given, the limit resets to the default."},
      {"p number",
       "Loads the specific page (starting from 0). If no value is given, the page resets to page 0."},
      {"f", "Open a form modal to define the work filter."},
      {"c", "Open a form modal to create a new work."},
      {"d", "Delete the selected work."},
      {"q", "Exit the application."},
    ]

    actions = Constants.items_table_help(nil, custom_controls)

    commands = [
      {"c", "continue"},
      {"q", "quit"}
    ]

    Modules.help(actions)
    Modules.commands(commands)
  end

  def render(_state) do
    work_state = StateServer.state(@pid)
    works = work_state.items
    cursor = work_state.cursor

    header =
      Modules.header_state(
        "Media Source",
        work_state.count,
        work_state.count_filter,
        work_state.offset,
        work_state.last
      )

    formatter = work_formatter(cursor)

    Modules.items_list(header, works, formatter)

    commands = [
      {"h", "help"},
      {"r", "refresh"},
      {"v", "view"},
      {"l", "limit"},
      {"p", "page"},
      {"f", "filter"},
      "\n",
      {"c", "create"},
      {"d", "delete"},
      {"q", "quit"}
    ]

    Modules.commands(commands)
  end

  @impl true
  def handle_event(%{show_help: false} = state, :up) do
    StateServer.decrease_cursor(@pid)
    {:same, state}
  end

  def handle_event(%{show_help: false} = state, :down) do
    StateServer.increase_cursor(@pid)
    {:same, state}
  end

  def handle_event(%{show_help: false} = state, :left) do
    case StateServer.prev_page(@pid) do
      {:same, _} ->
        {:keep, state}

      {:ok, _} ->
        {:same, state}
    end
  end

  def handle_event(%{show_help: false} = state, :right) do
    case StateServer.next_page(@pid) do
      {:same, _} ->
        {:same, state}

      {:ok, _} ->
        {:same, state}
    end

    {:same, state}
  end

  def handle_event(%{show_help: false} = state, {:char, "h"}) do
    state = Map.put(state, :show_help, true)
    {:same, state}
  end

  def handle_event(%{show_help: false} = state, {:char, "r"}) do
    StateServer.load_page(@pid)
    {:same, state}
  end

  def handle_event(%{show_help: false} = _state, {:char, "v"}) do
    {WorkView, WorkView.new_state()}
  end

  def handle_event(%{show_help: true} = state, {:char, "c"}) do
    state = Map.put(state, :show_help, false)
    {:same, state}
  end

  def handle_event(%{show_help: false} = _state, {:char, "c"}) do
    {ModalForm,
     ModalForm.new_state(
       "Create new Work",
       WorkTools.insert_definition(),
       [
         {"s", "save", fn state -> save(state) end},
         {"c", "cancel", fn _state -> back() end},
         {"q", "quit", fn state -> quit(state) end}
       ]
     )}
  end

  def handle_event(%{show_help: false} = _state, {:char, "d"}) do
    work_state = StateServer.state(@pid)
    work = Enum.at(work_state.items, work_state.cursor)

    {ModalConfirm,
     ModalConfirm.new_state(
       "The element '#{work.id}' will be deleted, are you sure?",
       [
         {"y", "yes", fn state -> delete(state, work.id) end},
         {"n", "no", fn _state -> back() end},
         {"q", "quit", fn state -> quit(state) end}
       ]
     )}
  end

  def handle_event(state, {:char, "q"}), do: {:quit, state}

  def handle_event(%{show_help: false} = state, {:char, text}) do
    if String.match?(text, ~r/^\d+$/) do
      new_cursor = String.to_integer(text)
      StateServer.set_cursor(@pid, new_cursor)
      {:same, state}
    else
      manage_text_as_basic_command(state, text)
    end
  end

  def handle_event(state, _) do
    {:same, state}
  end

  defp manage_text_as_basic_command(state, text) do
    case CoreUtils.parse_basic_command(text) do
      {:cmd, "l", rest} ->
        {_, limit} = NumberUtils.integer_parse(rest, StateServer.default_limit())
        StateServer.load_page(@pid, limit)
        {:same, state}

      {:cmd, "p", rest} ->
        {_, page} = NumberUtils.integer_parse(rest, 0)
        StateServer.goto_page(@pid, page)
        {:same, state}

      {:text, "l"} ->
        StateServer.load_page(@pid, StateServer.default_limit())
        {:same, state}

      {:text, "p"} ->
        StateServer.goto_page(@pid, 0)
        {:same, state}

      {:text, "f"} ->
        show_filter_modal()
    end
  end

  def show_filter_modal do
    {ModalForm,
     ModalForm.new_state(
       "Work Filter",
       WorkTools.filter_definition(),
       [
         {"a", "apply", fn state -> apply(state) end},
         {"r", "reset", fn state -> reset(state) end},
         {"c", "cancel", fn _state -> back() end},
         {"q", "quit", fn state -> quit(state) end}
       ],
       StateServer.get_filter(@pid),
       nil,
       Constants.filter_help()
     )}
  end

  defp work_formatter(cursor) do
    fn {work, idx} ->
      title = work.title || "(untitled)"
      type = work.type || "-"
      marker = if idx == cursor, do: "›", else: " "
      "#{marker} #{idx}.- [#{type}] #{title}"
    end
  end

  defp apply(state) do
    values = Map.get(state, :values, %{})
    StateServer.set_filter(@pid, values)
    back()
  end

  defp reset(_state) do
    StateServer.set_filter(@pid, %{})
    back()
  end

  defp save(state) do
    fields = Map.get(state, :fields, %{})
    values = Map.get(state, :values, %{})

    map = DefinitionUtils.definition_to_map(fields, values)
    work = WorkV1.from_map(map)

    StateServer.insert(@pid, work)

    back()
  end

  defp delete(state, id) do
    case StateServer.delete(@pid, id) do
      {:same, _} ->
        {:keep, state}

      {:ok, _} ->
        back()
    end
  end

  defp back, do: {ExStorage.TUI.Screen.WorkTable, new_state()}

  defp quit(state), do: {:quit, state}
end
