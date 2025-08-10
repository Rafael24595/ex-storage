defmodule ExStorage.Core.Work.StateServer do
  use GenServer

  # TODO: Inject the DB repository instead of using of ExStorage.DB.Client

  def start_link(_) do
    GenServer.start_link(__MODULE__, %ExStorage.Core.Work.State{}, name: __MODULE__)
  end

  def state(), do: GenServer.call(__MODULE__, :get_state)
  def refresh(), do: GenServer.call(__MODULE__, :refresh)
  def prev(limit \\ nil), do: GenServer.call(__MODULE__, {:prev, limit})
  def next(limit \\ nil), do: GenServer.call(__MODULE__, {:next, limit})
  def decrement_cursor(), do: GenServer.cast(__MODULE__, :decrement_cursor)
  def increment_cursor(), do: GenServer.cast(__MODULE__, :increment_cursor)

  @impl true
  def init(state), do: {:ok, state}

  @impl true
  def handle_call(:get_state, _from, state), do: {:reply, state, state}

  @impl true
  def handle_call(:refresh, _from, state) do
    limit = max(state.limit, 10)
    case fetch(state, limit, state.offset) do
      {:ok, new_state} ->
        {:reply, {:ok, new_state}, new_state}
      {:error, cause} ->
        Log.erro("An error occurred during work state server refreshing: #{inspect(cause)}")
        {:reply, {:ok, state}, state}
    end
  end

  @impl true
  def handle_call({:prev, limit}, _from, state) do
    limit = limit || state.limit || 10
    offset = max(state.offset - limit, 0)
    case fetch(state, limit, offset) do
      {:ok, new_state} ->
        {:reply, {:ok, new_state}, new_state}
      {:error, cause} ->
        Log.erro("An error occurred during work state server previous page fetching: #{inspect(cause)}")
        {:reply, {:ok, state}, state}
    end
  end

  @impl true
  def handle_call({:next, limit}, _from, state) do
    limit = limit || state.limit || 10
    offset = state.offset + limit
     case fetch(state, limit, offset) do
      {:ok, new_state} ->
        {:reply, {:ok, new_state}, new_state}
      {:error, cause} ->
        Log.erro("An error occurred during work state server next page fetching: #{inspect(cause)}")
        {:reply, {:ok, state}, state}
    end
  end

  @impl true
  def handle_cast(:decrement_cursor, state) do
    new_cursor = max(state.cursor - 1, 0)
    new_state = %{state | cursor: new_cursor}
    {:noreply, new_state}
  end

  @impl true
  def handle_cast(:increment_cursor, state) do
    total  = length(state.works)
    new_cursor = min(state.cursor + 1, max(total - 1, 0))
    new_state = %{state | cursor: new_cursor}
    {:noreply, new_state}
  end

  defp fetch(state, limit, offset) do
    query = "SELECT * FROM work LIMIT #{limit} START #{offset};"
    count_query = "SELECT count() FROM work GROUP BY count;"

    with {:ok, [%{"result" => works}]} <- ExStorage.DB.Client.query("test", "work", query),
         {:ok, [%{"result" => [%{"count" => count}]}]} <-
           ExStorage.DB.Client.query("test", "work", count_query) do
      processed_works = Enum.map(works, &ExStorage.Domain.Work.from_map/1)

      offset = min(offset, count)

      cond do
        offset == count and limit == state.limit ->
          {:ok, state}

        offset == count ->
          {:ok, %{state | limit: limit}}

        true ->
          last = min(offset + limit, count)
          new_state = %ExStorage.Core.Work.State{
            state
            | works: processed_works,
              cursor: 0,
              count: count,
              offset: offset,
              limit: limit,
              last: last
          }

          {:ok, new_state}
      end
    else
      {:ok, []} ->
        {:ok, state}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
