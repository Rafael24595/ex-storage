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

    pagination =
    if limit != nil and offset != nil do
      "LIMIT #{limit} START #{offset};"
    else
      ""
    end

    case Client.query("test", "work", "SELECT * FROM work #{pagination};") do
      {:ok, [%{"result" => works}]} ->
        {:ok, Enum.map(works, &ExStorage.Domain.Work.from_map/1)}

      {:ok, []} ->
        {:ok, []}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @spec create(ExStorage.Domain.Work.t()) :: {:error, any()} | {:ok, any()}
  def create(%ExStorage.Domain.Work{} = work) do
    json = Jason.encode!(ExStorage.Domain.Work.to_map(work))
    sql = "CREATE work CONTENT #{json};"

    case Client.query("test", "work", sql) do
      {:ok, [%{"result" => works}]} ->
        {:ok, works}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
