defmodule ExStorage.TUI.Screens.WorkTable do
  @behaviour ExStorage.TUI.Screen

  @impl true
  def onload(state) do
    ExStorage.Core.Work.StateServer.load_page()
    render(state)
  end

  @impl true
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
      {"r", "refresh"},
      {"v", "view"},
      {"c", "create"},
      {"d", "delete"},
      {"q", "quit"}
    ]

    ExStorage.TUI.Screens.Modules.commands(commands)
  end

  def print_sources_list(header, rows, formatter) do
    header = " #{header} "

    rows = Enum.with_index(rows)
    |> Enum.map(formatter)

    header_len = String.length(header)
    max_len =
      rows
      |> Enum.map(&String.length/1)
      |> Enum.max()

    max_len = max(max_len, header_len)

    header_limit = String.duplicate("-", header_len)
    limit = String.duplicate("-", max_len)

    IO.puts(header_limit)
    IO.puts(header)
    IO.puts(limit)

    Enum.each(rows, fn r -> IO.puts(r) end)
  end

  @impl true
  def handle_event(state, :up) do
    ExStorage.Core.Work.StateServer.decrease_cursor()
    {:same, state}
  end

  def handle_event(state, :down) do
    ExStorage.Core.Work.StateServer.increase_cursor()
    {:same, state}
  end

  def handle_event(state, :left) do
    case ExStorage.Core.Work.StateServer.prev_page() do
      {:same, _} ->
        {:keep, state}

      {:ok, _} ->
        {:same, state}
    end
  end

  def handle_event(state, :right) do
    case ExStorage.Core.Work.StateServer.next_page() do
      {:same, _} ->
        {:keep, state}

      {:ok, _} ->
        {:same, state}
    end

    {:same, state}
  end

  def handle_event(state, {:char, "r"}) do
    ExStorage.Core.Work.StateServer.load_page()
    {:same, state}
  end

  def handle_event(state, {:char, "c"}) do
    # TODO: Implement.
    # {ExStorage.TUI.Screens.NewWork, %{}}
    sample =
      ExStorage.Domain.Work.from_map(%{
        "title" => "Sample Work #{:os.system_time(:second)}",
        "type" => "novel",
        "creator" => "TUI",
        "released" => 2025,
        "concepts" => []
      })

    case ExStorage.DB.SurrealDB.Work.create(sample) do
      {:ok, _} ->
        ExStorage.Core.Work.StateServer.load_page()
        {:same, state}

      {:error, err} ->
        Log.erro("An error occured during work creation: #{inspect(err)}")
        {:same, state}
    end
  end

  def handle_event(_state, {:char, "v"}) do
    {ExStorage.TUI.Screens.WorkView, %{}}
  end

  def handle_event(_state, {:char, "d"}) do
    work_state = ExStorage.Core.Work.StateServer.state()
    work = Enum.at(work_state.works, work_state.cursor)

    {ExStorage.TUI.Screens.ModalConfirm,
     %{
       message: "The element '#{work.id}' will be deleted, are you sure?",
       options: [
         {"y", "yes", fn state -> delete(state, work.id) end},
         {"n", "no", fn _state -> back() end},
         {"q", "quit", fn state -> quit(state) end}
       ]
     }}
  end

  def handle_event(state, {:char, "q"}), do: {:quit, state}

  def handle_event(state, {:char, digits}) do
    if String.match?(digits, ~r/^\d+$/) do
      new_cursor = String.to_integer(digits)
      ExStorage.Core.Work.StateServer.set_cursor(new_cursor)
    end
    {:same, state}
  end

  def handle_event(state, _) do
    {:keep, state}
  end

  def delete(state, id) do
    case ExStorage.Core.Work.StateServer.delete(id) do
      {:same, _} ->
        {:keep, state}

      {:ok, _} ->
        back()
    end
  end

  def back(), do: {ExStorage.TUI.Screens.WorkTable, %{}}

  def quit(state), do: {:quit, state}
end
