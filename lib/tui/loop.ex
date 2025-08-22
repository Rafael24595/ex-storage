defmodule ExStorage.TUI.Loop do
  use GenServer
  alias ExStorage.TUI.Input

  def start_link(_args) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    Terminal.enable_raw_mode()

    screen = %{
      module: ExStorage.TUI.Screens.WorkTable,
      state: ExStorage.TUI.Screens.WorkTable.new_state()
    }

    {:ok, _task} = Task.start_link(fn -> input_loop(self()) end)

    send(self(), :onload)
    {:ok, screen}
  end

  @impl true
  def terminate(_reason, _state) do
    Terminal.disable_raw_mode()
    :ok
  end

  # TODO: Evalue use.
  def show_screen(module, state \\ %{}) when is_atom(module) do
    GenServer.cast(__MODULE__, {:switch_screen, module, state})
  end

  # TODO: Evalue use.
  def send_event(event) do
    GenServer.cast(__MODULE__, {:external_event, event})
  end

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
  def handle_cast({:input, event}, %{module: module, state: state} = screen) do
    case safe_handle_event(module, state, event) do
      {:quit, _new_state} ->
        Terminal.disable_raw_mode()
        IO.puts("\nExiting...")
        System.halt(0)
        {:stop, screen}

      {:same, new_state} ->
        new_screen = Map.put(screen, :state, new_state)
        send(self(), :render)
        {:noreply, new_screen}

      {:keep, new_state} ->
        new_screen = Map.put(screen, :state, new_state)
        {:noreply, new_screen}

      {new_module, new_state} when is_atom(new_module) ->
        new_screen =
          screen
          |> Map.put(:module, new_module)
          |> Map.put(:state, new_state)

        send(self(), :onload)
        {:noreply, new_screen}

      other ->
        Log.error("TUI: unexpected result from handle_event: #{inspect(other)}")
        {:noreply, screen}
    end
  end

  # TODO: Evalue use.
  def handle_cast({:external_event, event}, state), do: handle_cast({:input, event}, state)

  # TODO: Evalue use.
  def handle_cast({:switch_screen, module, state}, screen) do
    new_screen =
      screen
      |> Map.put(:module, module)
      |> Map.put(:state, state)

    send(self(), :render)
    {:noreply, new_screen}
  end

  @impl true
  def handle_info(:onload, %{module: module, state: state} = screen) do
    Terminal.clear()

    try do
      module.onload(state)
    rescue
      err ->
        message =
          "An error occurred during screen loading from #{inspect(module)} with state #{inspect(state)}"

        Log.error(message, err)
    end

    {:noreply, screen}
  end

  def handle_info(:render, %{module: module, state: state} = screen) do
    Terminal.clear()

    try do
      module.render(state)
    rescue
      err ->
        message =
          "An error occurred during screen rendering from #{inspect(module)} with state #{inspect(state)}."

        Log.error(message, err)
    end

    {:noreply, screen}
  end

  defp safe_handle_event(module, state, event) do
    try do
      module.handle_event(state, event)
    rescue
      err ->
        message =
          "An error occurred during event handling from #{inspect(module)} with state #{inspect(state)}."

        Log.error(message, err)

        {:same, state}
    end
  end
end
