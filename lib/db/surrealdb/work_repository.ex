defmodule ExStorage.DB.SurrealDB.WorkRepository do
  @behaviour ExStorage.DB.RepositoryWork

  use GenServer

  alias ExStorage.DB.SurrealDB.WorkState
  alias ExStorage.DB.SurrealDB.Connection
  alias ExStorage.DB.SurrealDB.Client, as: Client
  alias ExStorage.DB.SurrealDB.Utils, as: Utils
  alias ExStorage.Domain.Work, as: DomainWork

  @default_ns "test"
  @default_db "work"

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def init(_) do
    ns = System.get_env("SURREAL_WORK_NS") || @default_ns
    db = System.get_env("SURREAL_WORK_DB") || @default_db

    conn = Connection.new_connection(ns, db)
    state = WorkState.new_connection(conn)

    {:ok, state}
  end

  @impl true
  def count, do: GenServer.call(__MODULE__, :count)
  @impl true
  def count_filter(filter), do: GenServer.call(__MODULE__, {:count_filter, filter})
  @impl true
  def find(limit \\ nil, offset \\ nil, filter \\ nil), do: GenServer.call(__MODULE__, {:find, limit, offset, filter})
  @impl true
  def insert(format), do: GenServer.call(__MODULE__, {:insert, format})
  @impl true
  def delete(id \\ nil), do: GenServer.call(__MODULE__, {:delete, id})

  @impl true
  def handle_call(:count, _from, state) do
    conn = Map.get(state, :conn)

    case Client.query(conn, "SELECT count() FROM work GROUP BY count;") do
      {:ok, [%{"result" => [%{"count" => count}]}]} ->
        {:reply, {:ok, count}, state}

      {:ok, _} ->
        {:reply, {:ok, 0}, state}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  def handle_call({:count_filter, nil}, _from, state) do
    {:reply, nil ,state}
  end

  def handle_call({:count_filter, filter}, _from, state) do
    where = Utils.map_to_filter(filter || %{})

    if where == "" do
      {:reply, {:ok, nil}, state}
    else
      conn = Map.get(state, :conn)

      query = "SELECT count() FROM work #{where} GROUP BY count;"

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

    query = "SELECT * FROM work#{clause};"

    case Client.query(conn, query) do
      {:ok, [%{"result" => works}]} ->
        domain_works = Enum.map(works, &DomainWork.from_map/1)
        {:reply, {:ok, domain_works}, state}

      {:ok, []} ->
        {:reply, {:ok, []}, state}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  def handle_call({:insert, work}, _from, state) do
    conn = Map.get(state, :conn)

    json = Jason.encode!(DomainWork.to_map(work))
    sql = "CREATE work CONTENT #{json};"

    case Client.query(conn, sql) do
      {:ok, [%{"result" => works}]} ->
        domain_works = Enum.map(works, &DomainWork.from_map/1)
        {:reply, {:ok, domain_works}, state}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  def handle_call({:delete, id}, _from, state) do
    conn = Map.get(state, :conn)

    sql = "DELETE #{id || "work"};"

    with {:ok, work} <- find_one(conn, id),
         {:ok, _} <- Client.query(conn, sql) do
      {:reply, {:ok, work}, state}
    else
      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  defp find_one(conn, id) do
    if id != nil do
      case Client.query(conn, "SELECT * FROM #{id};") do
        {:ok, [%{"result" => works}]} ->
          {:ok, DomainWork.from_map(hd(works))}

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
