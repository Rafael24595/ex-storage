defmodule ExStorage.TUI.Screens.WorkTable do
  @behaviour ExStorage.TUI.Screen

  @impl true
  def onload(state) do
    ExStorage.Core.Work.StateServer.refresh()
    render(state)
  end

  @impl true
  def render(_state) do
    work_state = ExStorage.Core.Work.StateServer.state()
    works = work_state.works
    cursor = work_state.cursor
    from = work_state.offset
    to = work_state.last

    header = "Media Source (#{length(works)}) [#{from} - #{to}]"

    formatter = fn {w, i} ->
      title = w.title || "(untitled)"
      type = w.type || "-"
      marker = if i == cursor, do: "›", else: " "
      "#{marker} [#{type}] #{title}"
    end

    ExStorage.TUI.Screens.Utils.print_sources_list(header, works, formatter)

    commands = [
      {"↑"}, {"↓"}, {"←"}, {"→"},
      {"r", "refresh"},
      {"n", "new"},
      {"v", "view"},
      {"q", "quit"}
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

  def handle_event(state, {:char, "r"}) do
    ExStorage.Core.Work.StateServer.refresh()
    {:same, state}
  end

  def handle_event(state, {:char, "n"}) do
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
        ExStorage.Core.Work.StateServer.refresh()
        {:same, state}

      {:error, err} ->
        Log.erro("An error occured during work creation: #{inspect(err)}")
        {:same, state}
    end
  end

  def handle_event(_state, {:char, "v"}) do
    {ExStorage.TUI.Screens.WorkView, %{}}
  end

  def handle_event(state, {:char, "q"}), do: {:quit, state}

  def handle_event(state, _) do
    {:keep, state}
  end
end
