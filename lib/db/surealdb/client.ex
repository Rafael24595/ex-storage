defmodule ExStorage.DB.SurrealDB.Client do
  use GenServer

  @default_url "http://127.0.0.1:8000/rpc"
  @default_user "root"
  @default_pass "root"
  @default_ns "test"
  @default_db "work"

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def query(ns, db, sql) when is_binary(sql) do
    focused_sql = "USE NS #{ns} DB #{db}; #{sql}"

    case GenServer.call(__MODULE__, {:query, focused_sql}, 10_000) do
      {:ok, %{"result" => [_use_result | rest]}} ->
        {:ok, rest}

      other ->
        other
    end
  end

  @impl true
  def init(_) do
    state = %{
      url: System.get_env("SURREAL_URL") || @default_url,
      user: System.get_env("SURREAL_USER") || @default_user,
      pass: System.get_env("SURREAL_PASS") || @default_pass,
      ns: System.get_env("SURREAL_NS") || @default_ns,
      db: System.get_env("SURREAL_DB") || @default_db
    }

    {:ok, state}
  end

  @impl true
  def handle_call({:query, sql}, _from, state) do
    body =
      %{
        id: :os.system_time(:millisecond),
        method: "query",
        params: [sql],
        jsonrpc: "2.0"
      }
      |> Jason.encode!()

    headers = [
      {"Content-Type", "application/json"},
      {"Accept", "application/json"},
      {"NS", state.ns},
      {"DB", state.db},
      # TODO: Use JWT instead basic auth.
      {"Authorization", "Basic " <> Base.encode64("#{state.user}:#{state.pass}")}
    ]

    case HTTPoison.post(state.url, body, headers, recv_timeout: 10_000) do
      {:ok, %{status_code: 200, body: resp_body}} ->
        case Jason.decode(resp_body) do
          {:ok, decoded} ->
            {:reply, {:ok, decoded}, state}

          {:error, err} ->
            {:reply, {:error, {:json_decode, err}}, state}
        end

      {:ok, %{status_code: code, body: resp}} ->
        {:reply, {:error, {:http_error, code, resp}}, state}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end
end
