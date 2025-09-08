defmodule ExStorage.Core.Work.StateServer do
  @moduledoc """
  A `GenServer` responsible for managing the state of work items in ExStorage.

  This server provides:

    * Storage and retrieval of the current `ExStorage.Core.Work.State`
    * Insertion and deletion of works through the configured repository
    * Pagination controls (`load_page/0`, `goto_page/1`, `prev_page/1`, `next_page/1`)
    * Cursor management for navigating works (`increase_cursor/0`, `decrease_cursor/0`, `set_cursor/1`)

  The server initializes with the repository defined in
  `:ex_storage, :work_repo` unless explicitly provided.
  """

  use GenServer

  alias ExStorage.Core.Utils
  alias ExStorage.Core.Work.State
  alias ExStorage.Domain.Utils, as: DomainUtils
  alias ExStorage.Domain.Work, as: DomainWork

  @default_limit 10

  def start_link(repository \\ nil) do
    repository = if repository == [], do: nil, else: repository
    GenServer.start_link(__MODULE__, repository, name: __MODULE__)
  end

  @impl true
  def init(repository) do
    repository = repository || Application.fetch_env!(:ex_storage, :work_repo)
    state = State.new_state(repository)
    {:ok, state}
  end

  def default_limit, do: @default_limit

  def state, do: GenServer.call(__MODULE__, :state)

  def insert(work), do: GenServer.call(__MODULE__, {:insert, work})
  def delete(id \\ nil), do: GenServer.call(__MODULE__, {:delete, id})

  def load_page, do: GenServer.call(__MODULE__, :load_page)
  def load_page(limit), do: GenServer.call(__MODULE__, {:load_page, limit})
  def goto_page(page), do: GenServer.call(__MODULE__, {:goto_page, page})
  def prev_page(limit \\ nil), do: GenServer.call(__MODULE__, {:prev_page, limit})
  def next_page(limit \\ nil), do: GenServer.call(__MODULE__, {:next_page, limit})
  def get_filter, do: GenServer.call(__MODULE__, :get_filter)
  def set_filter(filter), do: GenServer.call(__MODULE__, {:set_filter, filter})

  def decrease_cursor, do: GenServer.cast(__MODULE__, :decrease_cursor)
  def increase_cursor, do: GenServer.cast(__MODULE__, :increase_cursor)
  def set_cursor(cursor), do: GenServer.cast(__MODULE__, {:set_cursor, cursor})

  @impl true
  def handle_call(:state, _from, state), do: {:reply, state, state}

  def handle_call({:insert, work}, _from, state) do
    case state.repository.insert(work) do
      {:ok, _} ->
        fetch(state)

      {:error, cause} ->
        Log.error("An error occurred during work insert: #{inspect(cause)}")

        {:reply, {:ok, state}, state}
    end
  end

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
    new_state = Map.put(state, :limit, limit)
    fetch(new_state)
  end

  def handle_call({:goto_page, page}, _from, state) do
    limit = state.limit || @default_limit
    offset = min(limit * page, limit * floor(state.count / limit))
    offset = max(offset, 0)

    new_state = Map.put(state, :limit, limit)

    fetch(new_state, offset)
  end

  def handle_call({:prev_page, limit}, _from, state) do
    limit = limit || state.limit || @default_limit
    offset = max(state.offset - limit, 0)

    new_state = Map.put(state, :limit, limit)

    fetch(new_state, offset)
  end

  def handle_call({:next_page, limit}, _from, state) do
    limit = limit || state.limit || @default_limit
    offset = state.offset + limit

    new_state = Map.put(state, :limit, limit)

    fetch(new_state, offset)
  end

  def handle_call(:get_filter, _from, state) do
    filter = Map.get(state, :filter, {})
    {:reply, filter, state}
  end

  def handle_call({:set_filter, filter}, _from, state) when is_map(filter) do
    new_state =
      state
      |> Map.put(:filter, filter)
      |> Map.put(:offset, 0)

    fetch(new_state)
  end

  def handle_call({:set_filter, filter}, _from, state) do
    Log.error(
      "An error occurred during work state server filter update: Filter is not a map",
      filter
    )

    {:reply, {:ok, state}, state}
  end

  @impl true
  def handle_cast(:decrease_cursor, state) do
    new_cursor = Utils.decrease_cursor(state.cursor, state.works)
    new_state = Map.put(state, :cursor, new_cursor)
    {:noreply, new_state}
  end

  def handle_cast(:increase_cursor, state) do
    new_cursor = Utils.increase_cursor(state.cursor, state.works)
    new_state = Map.put(state, :cursor, new_cursor)
    {:noreply, new_state}
  end

  def handle_cast({:set_cursor, cursor}, state) do
    total = length(state.works)
    new_cursor = max(cursor, 0)
    new_cursor = min(new_cursor, max(total - 1, 0))
    new_state = Map.put(state, :cursor, new_cursor)
    {:noreply, new_state}
  end

  defp fetch(state) do
    offset = Map.get(state, :offset, 0)
    fetch(state, offset)
  end

  defp fetch(state, offset) do
    limit = Map.get(state, :limit, 10)

    filter_definition = DomainWork.filter_definition()
    filter_values = Map.get(state, :filter, %{})

    filter = DomainUtils.definition_to_map(filter_definition, filter_values)

    Log.debug(filter)

    with {:ok, works} <- state.repository.find(limit, offset, filter),
         {:ok, count} <- state.repository.count() do
      len = length(works)
      sum = if len < limit, do: min(len + offset, count), else: count

      offset = min(offset, sum)

      if offset == sum do
        {:reply, {:ok, state}, state}
      else
          last = min(offset + limit, sum)

          new_state =
            state
            |> Map.put(:works, works)
            |> Map.put(:cursor, 0)
            |> Map.put(:count, count)
            |> Map.put(:offset, offset)
            |> Map.put(:last, last)

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
