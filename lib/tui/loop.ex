defmodule ExStorage.TUI.Loop do
  use GenServer
  alias ExStorage.TUI.Input

  @default_screen ExStorage.TUI.Screens.WorksList

  def start_link(_args) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    Terminal.enable_raw_mode()

    state = %{
      screen: @default_screen,
      screen_state: %{works: [], cursor: 0}
    }

    {:ok, _task} = Task.start_link(fn -> input_loop(self()) end)

    send(self(), :onload)
    {:ok, state}
  end

  @impl true
  def terminate(_reason, _state) do
    Terminal.disable_raw_mode()
    :ok
  end

  def show_screen(screen_module, screen_state \\ %{}) when is_atom(screen_module) do
    GenServer.cast(__MODULE__, {:switch_screen, screen_module, screen_state})
  end

  def send_event(event) do
    GenServer.cast(__MODULE__, {:external_event, event})
  end

  defp clear, do: IO.write("\e[2J\e[H")

  defp input_loop(server) do
    case Input.read_event() do
      :eof ->
        :ok

      event ->
        GenServer.cast(__MODULE__, {:input, event})
        input_loop(server)
    end
  end

  @impl true
  def handle_cast({:input, :quit}, state) do
    Terminal.disable_raw_mode()
    IO.puts("\nExiting...")
    System.halt(0)
    {:stop, :normal, state}
  end

  def handle_cast({:input, event}, %{screen: screen_mod, screen_state: scr_state} = state) do
    case safe_handle_event(screen_mod, scr_state, event) do
      {:quit, next_scr_state} ->
        {:stop, :normal, %{state | screen_state: next_scr_state}}

      {:same, next_scr_state} ->
        new_state = %{state | screen_state: next_scr_state}
        send(self(), :render)
        {:noreply, new_state}

      {:keep, next_scr_state} ->
        new_state = %{state | screen_state: next_scr_state}
        {:noreply, new_state}

      {next_screen_mod, next_scr_state} when is_atom(next_screen_mod) ->
        new_state = %{state | screen: next_screen_mod, screen_state: next_scr_state}
        send(self(), :onload)
        {:noreply, new_state}

      other ->
        Log.erro("TUI: unexpected result from handle_event: #{inspect(other)}")
        {:noreply, state}
    end
  end

  def handle_cast({:external_event, event}, state), do: handle_cast({:input, event}, state)

  def handle_cast({:switch_screen, screen_mod, screen_state}, state) do
    new_state = %{state | screen: screen_mod, screen_state: screen_state}
    send(self(), :render)
    {:noreply, new_state}
  end

  @impl true
  def handle_info(:onload, %{screen: screen_mod, screen_state: scr_state} = state) do
    clear()
    try do
      screen_mod.onload(scr_state)
    rescue
      err ->
        Log.erro("An error occurred during screen #{inspect(screen_mod)} loading: #{inspect(err)}")
    end

    {:noreply, state}
  end

  @impl true
  def handle_info(:render, %{screen: screen_mod, screen_state: scr_state} = state) do
    clear()
    try do
      screen_mod.render(scr_state)
    rescue
      err ->
        Log.erro("An error occurred during screen #{inspect(screen_mod)} rendering: #{inspect(err)}")
    end

    {:noreply, state}
  end

  defp safe_handle_event(screen_mod, scr_state, event) do
    try do
      screen_mod.handle_event(scr_state, event)
    rescue
      err ->
        Log.erro("An error occurred during event handling from #{inspect(screen_mod)}: #{inspect(err)}")
        {:same, scr_state}
    end
  end
end
