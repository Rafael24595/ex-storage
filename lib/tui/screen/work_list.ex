defmodule ExStorage.TUI.Screens.WorksList do
  @behaviour ExStorage.TUI.Screen

  alias ExStorage.DB.Queries

  @impl true
  def render(state) do
    works = Map.get(state, :works, [])
    sel   = Map.get(state, :cursor, 0)

    IO.puts("Media Source (#{length(works)})")
    IO.puts("------------------------------")

    Enum.with_index(works)
    |> Enum.each(fn {w, idx} ->
      title  = w.title || "(untitled)"
      type   = w.type || "-"
      marker = if idx == sel, do: "›", else: " "
      IO.puts("#{marker} #{title} (#{type})")
    end)

    IO.puts("\nCommands: ↑ ↓  r=refresh  n=new  q=quit")
  end

  @impl true
  def handle_event(state, :up) do
    cursor = Map.get(state, :cursor, 0)
    new_cursor = max(cursor - 1, 0)
    {:same, %{state | cursor: new_cursor}}
  end

  def handle_event(state, :down) do
    cursor = Map.get(state, :cursor, 0)
    total  = length(Map.get(state, :works, []))
    new_cursor = min(cursor + 1, max(total - 1, 0))
    {:same, %{state | cursor: new_cursor}}
  end

  def handle_event(state, {:char, "r"}) do
    {:same, refresh_works(state)}
  end

  def handle_event(_state, {:char, "n"}) do
    # TODO: Implement.
    {ExStorage.TUI.Screens.NewWork, %{}}
  end

  def handle_event(state, {:char, "q"}), do: {:quit, state}

  def handle_event(state, _) do
    {:same, state}
  end

  # TODO: Implement módule status.
  defp refresh_works(state) do
    case Queries.find_works() do
      {:ok, works_list} ->
        %{state | works: works_list, cursor: 0}

      {:error, reason} ->
        IO.puts("Error during works fetch: #{inspect(reason)}")
        state
    end
  end
end
