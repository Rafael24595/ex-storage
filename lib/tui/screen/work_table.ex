defmodule ExStorage.TUI.Screens.WorkTable do
  @behaviour ExStorage.TUI.Screen

  alias ExStorage.Core.Utils
  alias ExStorage.Core.Work.StateServer

  def new_state() do
    %{
      show_help: false
    }
  end

  @impl true
  def onload(state) do
    ExStorage.Core.Work.StateServer.load_page()
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

    ExStorage.TUI.Screens.Modules.help(actions)
    ExStorage.TUI.Screens.Modules.commands(commands)
  end

  def render(_state) do
    work_state = ExStorage.Core.Work.StateServer.state()
    works = work_state.works
    cursor = work_state.cursor
    count = work_state.count
    from = work_state.offset
    to = work_state.last

    header = "Media Source (#{count}) [#{from} - #{to}]"

    formatter = fn {w, i} ->
      title = w.title || "(untitled)"
      type = w.type || "-"
      marker = if i == cursor, do: "›", else: " "
      "#{marker} #{i}.- [#{type}] #{title}"
    end

    print_sources_list(header, works, formatter)

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

    ExStorage.TUI.Screens.Modules.commands(commands)
  end

  defp print_sources_list(header, rows, formatter) do
    header = " #{header} "

    rows =
      Enum.with_index(rows)
      |> Enum.map(formatter)

    header_len = String.length(header)

    max_len =
      rows
      |> Enum.map(&String.length/1)
      |> Enum.max(fn -> 0 end)

    max_len = max(max_len, header_len)

    header_limit = String.duplicate("-", header_len)
    limit = String.duplicate("-", max_len)

    IO.puts(header_limit)
    IO.puts(header)
    IO.puts(limit)

    Enum.each(rows, fn r -> IO.puts(r) end)
  end

  @impl true
  def handle_event(%{show_help: false} = state, :up) do
    ExStorage.Core.Work.StateServer.decrease_cursor()
    {:same, state}
  end

  def handle_event(%{show_help: false} = state, :down) do
    ExStorage.Core.Work.StateServer.increase_cursor()
    {:same, state}
  end

  def handle_event(%{show_help: false} = state, :left) do
    case ExStorage.Core.Work.StateServer.prev_page() do
      {:same, _} ->
        {:keep, state}

      {:ok, _} ->
        {:same, state}
    end
  end

  def handle_event(%{show_help: false} = state, :right) do
    case ExStorage.Core.Work.StateServer.next_page() do
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
    ExStorage.Core.Work.StateServer.load_page()
    {:same, state}
  end

  def handle_event(%{show_help: false} = _state, {:char, "v"}) do
    {ExStorage.TUI.Screens.WorkView, ExStorage.TUI.Screens.WorkView.new_state()}
  end

  def handle_event(%{show_help: true} = state, {:char, "c"}) do
    state = Map.put(state, :show_help, false)
    {:same, state}
  end

  def handle_event(%{show_help: false} = _state, {:char, "c"}) do
    {ExStorage.TUI.Screens.ModalForm,
     ExStorage.TUI.Screens.ModalForm.new_state(
       "Create new Work",
       ExStorage.Domain.Work.definition(),
       [
         {"s", "save", fn _state -> back() end},
         {"c", "cancel", fn _state -> back() end},
         {"q", "quit", fn state -> quit(state) end}
       ]
     )}
  end

  def handle_event(%{show_help: false} = _state, {:char, "d"}) do
    work_state = ExStorage.Core.Work.StateServer.state()
    work = Enum.at(work_state.works, work_state.cursor)

    {ExStorage.TUI.Screens.ModalConfirm,
     ExStorage.TUI.Screens.ModalConfirm.new_state(
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
    cond do
      String.match?(text, ~r/^\d+$/) ->
        new_cursor = String.to_integer(text)
        ExStorage.Core.Work.StateServer.set_cursor(new_cursor)

      true ->
        manage_text_as_basic_command(state, text)
    end
  end

  def handle_event(state, _) do
    {:same, state}
  end

  defp manage_text_as_basic_command(state, text) do
    case Utils.parse_basic_command(text) do
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

  defp delete(state, id) do
    case ExStorage.Core.Work.StateServer.delete(id) do
      {:same, _} ->
        {:keep, state}

      {:ok, _} ->
        back()
    end
  end

  defp back(), do: {ExStorage.TUI.Screens.WorkTable, new_state()}

  defp quit(state), do: {:quit, state}
end
