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

  def info(message, references \\ []),
    do: GenServer.cast(__MODULE__, {:record, "INFO", message, references})

  def warn(message, references \\ []),
    do: GenServer.cast(__MODULE__, {:record, "WARN", message, references})

  def error(message, cause \\ nil, references \\ [])

  def error(message, nil, references) do
    GenServer.cast(__MODULE__, {:record, "ERROR", message, references})
  end

  def error(message, cause, references) do
    message = "#{message}. Cause: #{inspect(cause)}"
    GenServer.cast(__MODULE__, {:record, "ERROR", message, references})
  end

  def debug(message) when is_binary(message),
    do: GenServer.cast(__MODULE__, {:record, "DEBUG", message, []})

  def debug(message), do: GenServer.cast(__MODULE__, {:record, "DEBUG", inspect(message)})

  @impl true
  def init(state), do: {:ok, state}

  @impl true
  def handle_call(:records, _from, state), do: {:reply, state, state}

  @impl true
  def handle_cast({:record, category, message, references}, state) do
    references_str = Enum.map(references, &to_string/1)

    record =
      ExStorage.Log.Record.from_map(%{
        "session_id" => state.session_id,
        "category" => category,
        "message" => message,
        "references" => references_str,
        "timestamp" => :os.system_time(:second)
      })

    records = Map.get(state, :records, []) ++ [record]
    new_state = Map.put(state, :records, records)

    file = "#{@log_path}/log_#{state.session_id}.jsonl"

    line =
      record
      |> ExStorage.Log.Record.to_map()
      |> Jason.encode!()

    File.mkdir_p!(@log_path)
    File.write!(file, line <> "\n", [:append])

    {:noreply, new_state}
  end
end
