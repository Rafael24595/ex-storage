defmodule ExStorage.Core.Worker.StateServer do
  use GenServer

  alias ExStorage.Core.Utils
  alias ExStorage.Core.Worker.State

  @default_limit 10

  def start_link({name, service, repository}) do
    GenServer.start_link(__MODULE__, {service, repository}, name: name)
  end

  @impl true
  def init({service, repository}) do
    state = State.new_state(service, repository)
    {:ok, state}
  end

  def default_limit, do: @default_limit

  def state(pid), do: GenServer.call(pid, :state)

  def insert(pid, items), do: GenServer.call(pid, {:insert, items})
  def delete(pid, id \\ nil), do: GenServer.call(pid, {:delete, id})

  def load_page(pid), do: GenServer.call(pid, :load_page)
  def load_page(pid, limit), do: GenServer.call(pid, {:load_page, limit})
  def goto_page(pid, page), do: GenServer.call(pid, {:goto_page, page})
  def prev_page(pid, limit \\ nil), do: GenServer.call(pid, {:prev_page, limit})
  def next_page(pid, limit \\ nil), do: GenServer.call(pid, {:next_page, limit})
  def get_filter(pid), do: GenServer.call(pid, :get_filter)
  def set_filter(pid, filter), do: GenServer.call(pid, {:set_filter, filter})

  def decrease_cursor(pid), do: GenServer.cast(pid, :decrease_cursor)
  def increase_cursor(pid), do: GenServer.cast(pid, :increase_cursor)
  def set_cursor(pid, cursor), do: GenServer.cast(pid, {:set_cursor, cursor})

  @impl true
  def handle_call(:state, _from, state), do: {:reply, state, state}

  def handle_call({:insert, items}, _from, state) do
    case state.repository.insert(items) do
      {:ok, _} ->
        fetch(state)

      {:error, cause} ->
        Log.error("An error occurred during items insert: #{inspect(cause)}")

        {:reply, {:ok, state}, state}
    end
  end

  def handle_call({:delete, id}, _from, state) do
    case state.repository.delete(id) do
      {:ok, _} ->
        fetch(state)

      {:error, cause} ->
        Log.error("An error occurred during item deleting: #{inspect(cause)}")

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
      |> Map.put(:items, [])
      |> Map.put(:last, 0)

    fetch(new_state)
  end

  def handle_call({:set_filter, filter}, _from, state) do
    Log.error(
      "An error occurred during state server filter update: Filter is not a map",
      filter
    )

    {:reply, {:ok, state}, state}
  end

  @impl true
  def handle_cast(:decrease_cursor, state) do
    new_cursor = Utils.decrease_cursor(state.cursor, state.items)
    new_state = Map.put(state, :cursor, new_cursor)
    {:noreply, new_state}
  end

  def handle_cast(:increase_cursor, state) do
    new_cursor = Utils.increase_cursor(state.cursor, state.items)
    new_state = Map.put(state, :cursor, new_cursor)
    Log.debug(state)
    {:noreply, new_state}
  end

  def handle_cast({:set_cursor, cursor}, state) do
    total = length(state.items)
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
    new_state =
      case state.service.fetch(state, offset) do
        {:ok, new_state} ->
          new_state

        {:error, new_state, reason} ->
          Log.error("An error occurred during state server fetching", reason)
          new_state
      end

    {:reply, {:ok, new_state}, new_state}
  end
end
