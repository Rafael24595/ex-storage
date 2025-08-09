defmodule ExStorage.DB.Queries do
  def find_works do
    case ExStorage.DB.Client.query("test", "work", "SELECT * FROM work;") do
      {:ok, [%{"result" => works}]} ->
        {:ok, Enum.map(works, &ExStorage.Domain.Work.from_map/1)}

      {:ok, []} ->
        {:ok, []}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def create_work(%ExStorage.Domain.Work{} = work) do
    json = Jason.encode!(ExStorage.Domain.Work.to_map(work))
    sql = "CREATE work CONTENT #{json};"

    case ExStorage.DB.Client.query("test", "work", sql) do
      {:ok, [%{"result" => works}]} ->
        {:ok, works}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
