defmodule ExStorage.Core.Work.StateServer do
  use GenServer

  @default_limit 10

  def start_link(repository \\ nil) do
    repository = if repository == [], do: nil, else: repository
    GenServer.start_link(__MODULE__, repository, name: __MODULE__)
  end

  @impl true
  def init(repository) do
    repository = repository || Application.fetch_env!(:ex_storage, :work_repo)
    {:ok, %ExStorage.Core.Work.State{repository: repository}}
  end

  def default_limit, do: @default_limit

  def state(), do: GenServer.call(__MODULE__, :state)

  def delete(id \\ nil), do: GenServer.call(__MODULE__, {:delete, id})

  def load_page(), do: GenServer.call(__MODULE__, :load_page)
  def load_page(limit), do: GenServer.call(__MODULE__, {:load_page, limit})
  def prev_page(limit \\ nil), do: GenServer.call(__MODULE__, {:prev_page, limit})
  def next_page(limit \\ nil), do: GenServer.call(__MODULE__, {:next_page, limit})

  def decrease_cursor(), do: GenServer.cast(__MODULE__, :decrease_cursor)
  def increase_cursor(), do: GenServer.cast(__MODULE__, :increase_cursor)
  def set_cursor(cursor), do: GenServer.cast(__MODULE__, {:set_cursor, cursor})

  @impl true
  def handle_call(:state, _from, state), do: {:reply, state, state}

  def handle_call({:delete, id}, _from, state) do
    case state.repository.delete(id) do
      {:ok, _} ->
        fetch(state)

      {:error, cause} ->
        Log.error("An error occurred during work deleting: #{inspect(cause)}")

        {:reply, {:ok, state}, state}
    end
  end

  def handle_call(:load_page, _from, state) do
    fetch(state)
  end

  def handle_call({:load_page, limit}, _from, state) do
    fetch(state, limit, state.offset)
  end

  def handle_call({:prev_page, limit}, _from, state) do
    limit = limit || state.limit || 10
    offset = max(state.offset - limit, 0)

    fetch(state, limit, offset)
  end

  def handle_call({:next_page, limit}, _from, state) do
    limit = limit || state.limit || 10
    offset = state.offset + limit

    fetch(state, limit, offset)
  end

  @impl true
  def handle_cast(:decrease_cursor, state) do
    new_cursor = ExStorage.Core.Utils.decrease_cursor(state.cursor, state.works)
    new_state = %{state | cursor: new_cursor}
    {:noreply, new_state}
  end

  def handle_cast(:increase_cursor, state) do
    new_cursor = ExStorage.Core.Utils.increase_cursor(state.cursor, state.works)
    new_state = %{state | cursor: new_cursor}
    {:noreply, new_state}
  end

  def handle_cast({:set_cursor, cursor}, state) do
    total = length(state.works)
    new_cursor = max(cursor, 0)
    new_cursor = min(new_cursor, max(total - 1, 0))
    new_state = %{state | cursor: new_cursor}
    {:noreply, new_state}
  end

  defp fetch(state) do
    limit = max(state.limit, 10)
    fetch(state, limit, state.offset)
  end

  defp fetch(state, limit, offset) do
    with {:ok, works} <- state.repository.find(limit, offset),
         {:ok, count} <- state.repository.count() do
      offset = min(offset, count)

      cond do
        offset == state.offset and count == state.count and limit == state.limit ->
          {:reply, {:ok, state}, state}

        offset == count ->
          new_state = Map.put(state, :limit, limit)
          {:reply, {:ok, new_state}, new_state}

        true ->
          last = min(offset + limit, count)

          new_state = %ExStorage.Core.Work.State{
            state
            | works: works,
              cursor: 0,
              count: count,
              offset: offset,
              limit: limit,
              last: last
          }

          {:reply, {:ok, new_state}, new_state}
      end
    else
      {:ok, []} ->
        {:reply, {:ok, state}, state}

      {:error, reason} ->
        Log.error("An error occurred during work state server fetching", reason)
        {:reply, {:ok, state}, state}
    end
  end
end
