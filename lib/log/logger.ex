defmodule ExStorage.Log.Logger do
  use GenServer

  def start_link(session_id) do
    GenServer.start_link(
      __MODULE__,
      %{
        session_id: session_id,
        records: []
      },
      name: __MODULE__
    )
  end

  @log_path "log"

  def records, do: GenServer.call(__MODULE__, :records)
  def info(message), do: GenServer.cast(__MODULE__, {:record, "INFO", message})
  def warn(message), do: GenServer.cast(__MODULE__, {:record, "WARN", message})
  def error(message), do: GenServer.cast(__MODULE__, {:record, "ERROR", message})
  def debug(message), do: GenServer.cast(__MODULE__, {:record, "DEBUG", message})

  @impl true
  def init(state), do: {:ok, state}

  @impl true
  def handle_call(:records, _from, state), do: {:reply, state, state}

  @impl true
  def handle_cast({:record, category, message}, state) do
    record = ExStorage.Log.Record.from_map(%{
      "session_id" => state.session_id,
      "category" => category,
      "message" => message,
      "timestamp" => :os.system_time(:second),
    })

    records = Map.get(state, :records, []) ++ [record]
    new_state = Map.put(state, :records, records)

    file = "#{@log_path}/log_#{state.session_id}.jsonl"
    line = record
            |> ExStorage.Log.Record.to_map()
            |> Jason.encode!()
    File.mkdir_p!(@log_path)
    File.write!(file, line <> "\n", [:append])

    {:noreply, new_state}
  end
end
