defmodule ExStorage.DB.SurrealDB.Client do
  def query(conn, sql) when is_binary(sql) do
    focused_sql = "USE NS #{conn.ns} DB #{conn.db}; #{sql}"

    case fetch(conn, focused_sql) do
      {:ok, %{"result" => [_use_result | rest]}} ->
        {:ok, rest}

      other ->
        other
    end
  end

  defp fetch(conn, sql) do
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
      {"NS", conn.ns},
      {"DB", conn.db},
      # TODO: Use JWT instead basic auth.
      {"Authorization", "Basic " <> Base.encode64("#{conn.user}:#{conn.pass}")}
    ]

    case HTTPoison.post(conn.url, body, headers, recv_timeout: 10_000) do
      {:ok, %{status_code: 200, body: resp_body}} ->
        case Jason.decode(resp_body) do
          {:ok, decoded} ->
            {:ok, decoded}

          {:error, err} ->
            {:error, {:json_decode, err}}
        end

      {:ok, %{status_code: code, body: resp}} ->
        {:error, {:http_error, code, resp}}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
