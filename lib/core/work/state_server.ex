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

  def state(), do: GenServer.call(__MODULE__, :get_state)
  def refresh(), do: GenServer.call(__MODULE__, :refresh)
  def prev(limit \\ nil), do: GenServer.call(__MODULE__, {:prev, limit})
  def next(limit \\ nil), do: GenServer.call(__MODULE__, {:next, limit})
  def decrement_cursor(), do: GenServer.cast(__MODULE__, :decrement_cursor)
  def increment_cursor(), do: GenServer.cast(__MODULE__, :increment_cursor)

  @impl true
  def handle_call(:get_state, _from, state), do: {:reply, state, state}

  @impl true
  def handle_call(:refresh, _from, state) do
    limit = max(state.limit, 10)

    case fetch(state, limit, state.offset) do
      {:ok, new_state} ->
        {:reply, {:ok, new_state}, new_state}

      {:same, _state} ->
        {:reply, {:same, state}, state}

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

      {:same, _} ->
        {:reply, {:same, state}, state}

      {:error, cause} ->
        Log.erro(
          "An error occurred during work state server previous page fetching: #{inspect(cause)}"
        )

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

      {:same, _state} ->
        {:reply, {:same, state}, state}

      {:error, cause} ->
        Log.erro(
          "An error occurred during work state server next page fetching: #{inspect(cause)}"
        )

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
    total = length(state.works)
    new_cursor = min(state.cursor + 1, max(total - 1, 0))
    new_state = %{state | cursor: new_cursor}
    {:noreply, new_state}
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
