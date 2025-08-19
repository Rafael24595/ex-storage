defmodule ExStorage.DB.SurrealDB.Work do
  @behaviour ExStorage.DB.Work

  alias ExStorage.DB.SurrealDB.Client, as: Client

  def count do
    case Client.query("test", "work", "SELECT count() FROM work GROUP BY count;") do
      {:ok, [%{"result" => [%{"count" => count}]}]} ->
        {:ok, count}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def find(limit \\ nil, offset \\ nil) do
    limit = limit || 10

    page =
      if limit != nil and offset != nil do
        "LIMIT #{limit} START #{offset};"
      else
        ""
      end

    case Client.query("test", "work", "SELECT * FROM work #{page};") do
      {:ok, [%{"result" => works}]} ->
        {:ok, Enum.map(works, &ExStorage.Domain.Work.from_map/1)}

      {:ok, []} ->
        {:ok, []}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def find_one(id \\ nil) do
    if id != nil do
      case Client.query("test", "work", "SELECT * FROM #{id};") do
        {:ok, [%{"result" => works}]} ->
          {:ok, ExStorage.Domain.Work.from_map(hd(works))}

        {:ok, []} ->
          {:ok, nil}

        {:error, reason} ->
          {:error, reason}
      end
    else
      {:ok, nil}
    end
  end

  def create(%ExStorage.Domain.Work{} = work) do
    json = Jason.encode!(ExStorage.Domain.Work.to_map(work))
    sql = "CREATE work CONTENT #{json};"

    case Client.query("test", "work", sql) do
      {:ok, [%{"result" => works}]} ->
        {:ok, Enum.map(works, &ExStorage.Domain.Work.from_map/1)}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def delete(id \\ nil) do
    sql =
      if id == nil do
        "DELETE work;"
      else
        "DELETE #{id};"
      end

    with {:ok, work} <- find_one(id),
         {:ok, _} <- Client.query("test", "work", sql) do
      {:ok, work}
    else
      {:error, reason} -> {:error, reason}
    end
  end
end
