defmodule ExStorage.Core.Work.StateServer do
  use GenServer

  def start_link(repository \\ nil) do
    repository = if repository == [], do: nil, else: repository
    GenServer.start_link(__MODULE__, repository, name: __MODULE__)
  end

  @impl true
  def init(repository) do
    repository = repository || Application.fetch_env!(:ex_storage, :work_repo)
    {:ok, %ExStorage.Core.Work.State{repository: repository}}
  end

  def state(), do: GenServer.call(__MODULE__, :state)

  def delete(id \\ nil), do: GenServer.call(__MODULE__, {:delete, id})

  def load_page(), do: GenServer.call(__MODULE__, :load_page)
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
        case refresh(state) do
          {:ok, new_state} ->
            {:reply, {:ok, new_state}, new_state}

          {:error, cause} ->
            Log.erro(cause)
            {:reply, {:ok, state}, state}
        end

      {:error, cause} ->
        Log.erro("An error occurred during work deleting: #{inspect(cause)}")

        {:reply, {:ok, state}, state}
    end
  end

  def handle_call(:load_page, _from, state) do
    case refresh(state) do
      {:ok, new_state} ->
        {:reply, {:ok, new_state}, new_state}

      {:error, cause} ->
        Log.erro(cause)
        {:reply, {:ok, state}, state}
    end
  end

  def handle_call({:prev_page, limit}, _from, state) do
    limit = limit || state.limit || 10
    offset = max(state.offset - limit, 0)

    case fetch(state, limit, offset) do
      {:ok, new_state} ->
        {:reply, {:ok, new_state}, new_state}

      {:error, cause} ->
        Log.erro(
          "An error occurred during work state server previous page fetching: #{inspect(cause)}"
        )

        {:reply, {:ok, state}, state}
    end
  end

  def handle_call({:next_page, limit}, _from, state) do
    limit = limit || state.limit || 10
    offset = state.offset + limit

    case fetch(state, limit, offset) do
      {:ok, new_state} ->
        {:reply, {:ok, new_state}, new_state}

      {:error, cause} ->
        Log.erro(
          "An error occurred during work state server next page fetching: #{inspect(cause)}"
        )

        {:reply, {:ok, state}, state}
    end
  end

  @impl true
  def handle_cast(:decrease_cursor, state) do
    total = length(state.works)

    prev_cursor = state.cursor - 1

    new_cursor =
      if prev_cursor < 0 do
        max(total - 1, 0)
      else
        prev_cursor
      end

    new_state = %{state | cursor: new_cursor}
    {:noreply, new_state}
  end

  def handle_cast(:increase_cursor, state) do
    total = length(state.works)

    next_cursor = state.cursor + 1
    last_cursor = max(total - 1, 0)

    new_cursor =
      if next_cursor > last_cursor do
        0
      else
        next_cursor
      end

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

  defp refresh(state) do
    limit = max(state.limit, 10)

    case fetch(state, limit, state.offset) do
      {:ok, new_state} ->
        {:ok, new_state}

      {:error, cause} ->
        {:error, "An error occurred during work state server refreshing: #{inspect(cause)}"}
    end
  end

  defp fetch(state, limit, offset) do
    with {:ok, works} <- state.repository.find(limit, offset),
         {:ok, count} <- state.repository.count() do
      offset = min(offset, count)

      cond do
        offset == state.offset and count == state.count and limit == state.limit ->
          {:ok, state}

        offset == count ->
          {:ok, %{state | limit: limit}}

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
