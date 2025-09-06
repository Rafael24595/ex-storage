defmodule ExStorage.TUI.Screens.WorkTable do
  @moduledoc """
  TUI screen for listing, navigating, and managing works.

  This screen implements the `ExStorage.TUI.Screen` behaviour and acts as
  the main interface for interacting with `ExStorage.Domain.Work` entities
  through the terminal.

  ## State

  The screen’s state includes:

    * `:show_help` — toggles whether the help overlay is displayed.
  """

  @behaviour ExStorage.TUI.Screen

  alias ExStorage.Core.NumberUtils
  alias ExStorage.Core.Utils, as: CoreUtils
  alias ExStorage.Core.Work.StateServer
  alias ExStorage.Domain.{Utils, Work}
  alias ExStorage.TUI.Screens.ModalConfirm
  alias ExStorage.TUI.Screens.ModalForm
  alias ExStorage.TUI.Screens.Modules
  alias ExStorage.TUI.Screens.WorkView

  def new_state do
    %{
      show_help: false
    }
  end

  @impl true
  def onload(state) do
    StateServer.load_page()
    render(state)
  end

  @impl true
  def render(%{show_help: true} = _state) do
    actions = [
      {"↑ / ↓", "Move between works on the current page."},
      {"← / →", "Move between different work pages."},
      {"number", "Type an index to move the cursor to that work."},
      {"r", "Refresh the current page."},
      {"v", "Open a modal with the details of the selected work."},
      {"l number",
       "Set the number of items per page. If no value is given, the limit resets to the default."},
      {"p number",
       "Loads the specific page (starting from 0). If no value is given, the page resets to page 0."},
      {"c", "Open a form modal to create a new work."},
      {"d", "Delete the selected work."},
      {"q", "Exit the application."}
    ]

    commands = [
      {"c", "continue"},
      {"q", "quit"}
    ]

    Modules.help(actions)
    Modules.commands(commands)
  end

  def render(_state) do
    work_state = StateServer.state()
    works = work_state.works
    cursor = work_state.cursor

    header =
      Modules.header_state(
        "Media Source",
        work_state.count,
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
      "\n",
      {"c", "create"},
      {"d", "delete"},
      {"q", "quit"}
    ]

    Modules.commands(commands)
  end

  @impl true
  def handle_event(%{show_help: false} = state, :up) do
    StateServer.decrease_cursor()
    {:same, state}
  end

  def handle_event(%{show_help: false} = state, :down) do
    StateServer.increase_cursor()
    {:same, state}
  end

  def handle_event(%{show_help: false} = state, :left) do
    case StateServer.prev_page() do
      {:same, _} ->
        {:keep, state}

      {:ok, _} ->
        {:same, state}
    end
  end

  def handle_event(%{show_help: false} = state, :right) do
    case StateServer.next_page() do
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
    StateServer.load_page()
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
       Work.definition(),
       [
         {"s", "save", fn state -> save(state) end},
         {"c", "cancel", fn _state -> back() end},
         {"q", "quit", fn state -> quit(state) end}
       ]
     )}
  end

  def handle_event(%{show_help: false} = _state, {:char, "d"}) do
    work_state = StateServer.state()
    work = Enum.at(work_state.works, work_state.cursor)

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
      StateServer.set_cursor(new_cursor)
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
        StateServer.load_page(limit)

      {:cmd, "p", rest} ->
        {_, page} = NumberUtils.integer_parse(rest, 0)
        StateServer.goto_page(page)

      {:text, "l"} ->
        StateServer.load_page(StateServer.default_limit())

      {:text, "p"} ->
        StateServer.goto_page(0)
    end

    {:same, state}
  end

  defp work_formatter(cursor) do
    fn {work, idx} ->
      title = work.title || "(untitled)"
      type = work.type || "-"
      marker = if idx == cursor, do: "›", else: " "
      "#{marker} #{idx}.- [#{type}] #{title}"
    end
  end

  defp save(state) do
    fields = Map.get(state, :fields, %{})
    values = Map.get(state, :values, %{})

    map = Utils.definition_to_map(fields, values)
    work = Work.from_map(map)

    StateServer.insert(work)

    back()
  end

  defp delete(state, id) do
    case StateServer.delete(id) do
      {:same, _} ->
        {:keep, state}

      {:ok, _} ->
        back()
    end
  end

  defp back, do: {ExStorage.TUI.Screens.WorkTable, new_state()}

  defp quit(state), do: {:quit, state}
end
