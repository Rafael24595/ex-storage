defmodule ExStorage.TUI.Screens.WorksList do
  @behaviour ExStorage.TUI.Screen

  alias ExStorage.DB.Queries

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

    IO.puts("Media Source (#{length(works)}) [#{from} -> #{to}]")
    IO.puts("------------------------------")

    Enum.with_index(works)
    |> Enum.each(fn {w, idx} ->
      title  = w.title || "(untitled)"
      type   = w.type || "-"
      marker = if idx == cursor, do: "›", else: " "
      IO.puts("#{marker} #{title} (#{type})")
    end)

    IO.puts("\nCommands: ↑ ↓ ← →  r=refresh  n=new  q=quit")
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
    ExStorage.Core.Work.StateServer.prev()
    {:same, state}
  end

  def handle_event(state, :right) do
    ExStorage.Core.Work.StateServer.next()
    {:same, state}
  end

  def handle_event(state, {:char, "r"}) do
    ExStorage.Core.Work.StateServer.refresh()
    {:same, state}
  end

  def handle_event(state, {:char, "n"}) do
    # TODO: Implement.
    # {ExStorage.TUI.Screens.NewWork, %{}}
     sample = ExStorage.Domain.Work.from_map(%{
      "title" => "Sample Work #{:os.system_time(:second)}",
      "type" => "novel",
      "creator" => "TUI",
      "released" => 2025,
      "concepts" => []
    })

    case Queries.create_work(sample) do
      {:ok, _} ->
        ExStorage.Core.Work.StateServer.refresh()
        {:same, state}
      {:error, err} ->
        Log.erro("An error occured during work creation: #{inspect(err)}")
        {:same, state}
    end
  end

  def handle_event(state, {:char, "q"}), do: {:quit, state}

  def handle_event(state, _) do
    {:same, state}
  end

end
