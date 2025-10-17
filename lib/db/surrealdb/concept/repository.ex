defmodule ExStorage.DB.SurrealDB.ConceptRepository do
  @moduledoc """
  SurrealDB implementation of the Concept Repository.
  """

  @behaviour ExStorage.DB.RepositoryConcept

  use GenServer

  alias ExStorage.DB.SurrealDB.Client, as: Client
  alias ExStorage.DB.SurrealDB.ConceptState
  alias ExStorage.DB.SurrealDB.Connection
  alias ExStorage.DB.SurrealDB.Utils, as: Utils
  alias ExStorage.Domain.ConceptV1

  @default_ns "test"
  @default_db "concept"

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def init(_) do
    ns = System.get_env("SURREAL_CONCEPT_NS") || @default_ns
    db = System.get_env("SURREAL_CONCEPT_DB") || @default_db

    conn = Connection.new_connection(ns, db)
    state = ConceptState.new_connection(conn)

    {:ok, state}
  end

  @impl true
  def count, do: GenServer.call(__MODULE__, :count)
  @impl true
  def count_filter(filter), do: GenServer.call(__MODULE__, {:count_filter, filter})
  @impl true
  def find(limit \\ nil, offset \\ nil, filter \\ nil),
    do: GenServer.call(__MODULE__, {:find, limit, offset, filter})

  @impl true
  def insert(format), do: GenServer.call(__MODULE__, {:insert, format})
  @impl true
  def delete(id \\ nil), do: GenServer.call(__MODULE__, {:delete, id})

  @impl true
  def handle_call(:count, _from, state) do
    conn = Map.get(state, :conn)

    case Client.query(conn, "SELECT count() FROM #{state.conn.db} GROUP BY count;") do
      {:ok, [%{"result" => [%{"count" => count}]}]} ->
        {:reply, {:ok, count}, state}

      {:ok, _} ->
        {:reply, {:ok, 0}, state}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  def handle_call({:count_filter, nil}, _from, state) do
    {:reply, nil, state}
  end

  def handle_call({:count_filter, filter}, _from, state) do
    where = Utils.map_to_filter(filter || %{})

    if where == "" do
      {:reply, {:ok, nil}, state}
    else
      conn = Map.get(state, :conn)

      query = "SELECT count() FROM #{state.conn.db} #{where} GROUP BY count;"

      case Client.query(conn, query) do
        {:ok, [%{"result" => [%{"count" => count}]}]} ->
          {:reply, {:ok, count}, state}

        {:ok, _} ->
          {:reply, {:ok, 0}, state}

        {:error, reason} ->
          {:reply, {:error, reason}, state}
      end
    end
  end

  def handle_call({:find, limit, offset, filter}, _from, state) do
    conn = Map.get(state, :conn)

    where = Utils.map_to_filter(filter || %{})

    page =
      if offset != nil do
        "LIMIT #{limit || 10} START #{offset}"
      else
        ""
      end

    clause =
      [where, page]
      |> Enum.join(" ")

    clause = if clause == "", do: "", else: " #{clause}"

    query = "SELECT * FROM #{state.conn.db}#{clause};"

    case Client.query(conn, query) do
      {:ok, [%{"result" => concepts}]} ->
        domain_concepts = Enum.map(concepts, &ConceptV1.from_map/1)
        {:reply, {:ok, domain_concepts}, state}

      {:ok, []} ->
        {:reply, {:ok, []}, state}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  def handle_call({:insert, concept}, _from, state) do
    conn = Map.get(state, :conn)

    now = DateTime.utc_now()
    timestamp = DateTime.to_unix(now, :millisecond)

    concept_map =
      concept
      |> ConceptV1.to_map()
      |> Map.drop([:id])
      |> Map.put(:version, ConceptV1.version())
      |> Map.put(:timestamp, timestamp)

    json = Jason.encode!(concept_map)

    sql = "CREATE #{state.conn.db} CONTENT #{json};"

    case Client.query(conn, sql) do
      {:ok, [%{"result" => concepts}]} when is_list(concepts) ->
        domain_concepts = Enum.map(concepts, &ConceptV1.from_map/1)
        {:reply, {:ok, domain_concepts}, state}

      {:ok, [%{"result" => result}]} ->
        {:reply, {:error, result}, state}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  def handle_call({:delete, id}, _from, state) do
    conn = Map.get(state, :conn)

    sql = "DELETE #{id || state.conn.db};"

    with {:ok, concept} <- find_one(conn, id),
         {:ok, _} <- Client.query(conn, sql) do
      {:reply, {:ok, concept}, state}
    else
      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  defp find_one(conn, id) do
    if id != nil do
      case Client.query(conn, "SELECT * FROM #{id};") do
        {:ok, [%{"result" => concepts}]} ->
          {:ok, ConceptV1.from_map(hd(concepts))}

        {:ok, []} ->
          {:ok, nil}

        {:error, reason} ->
          {:error, reason}
      end
    else
      {:ok, nil}
    end
  end
end
