defmodule ExStorage.Core.StateServer do
  use GenServer

  def start_link(_) do
    GenServer.start_link(
      __MODULE__,
      %{
        works: [],
        cursor: 0
      },
      name: __MODULE__
    )
  end

  def get_state, do: GenServer.call(__MODULE__, :get_state)
  def set_works(works), do: GenServer.cast(__MODULE__, {:set_works, works})
  def set_cursor(idx), do: GenServer.cast(__MODULE__, {:set_cursor, idx})

  @impl true
  def init(state), do: {:ok, state}

  @impl true
  def handle_call(:get_state, _from, state), do: {:reply, state, state}

  @impl true
  def handle_cast({:set_works, works}, state) do
    new_state = Map.put(state, :works, works)
    {:noreply, new_state}
  end

  def handle_cast({:set_cursor, idx}, state) do
    new_state = Map.put(state, :cursor, idx)
    {:noreply, new_state}
  end
end
