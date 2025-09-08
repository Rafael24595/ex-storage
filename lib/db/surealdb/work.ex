defmodule ExStorage.DB.SurrealDB.Work do
  @moduledoc """
  SurrealDB implementation of the `ExStorage.DB.Work` behaviour.

  This module provides persistence for `ExStorage.Domain.Work` entities
  using [SurrealDB](https://surrealdb.com/). It translates repository
  operations into SurrealDB SQL queries via `ExStorage.DB.SurrealDB.Client`.

  ## Supported operations

    * `count/0` — Returns the total number of stored works.
    * `find/2` — Retrieves a list of works with optional `limit` and `offset`.
    * `find_one/1` — Retrieves a single work by its ID.
    * `insert/1` — Persists a new work and returns the inserted entity.
    * `delete/1` — Deletes a work by ID (or all works if `nil`) and returns
      the deleted entity.
  """

  @behaviour ExStorage.DB.Work

  alias ExStorage.DB.SurrealDB.Client, as: Client
  alias ExStorage.DB.SurrealDB.Utils, as: Utils

  def count do
    case Client.query("test", "work", "SELECT count() FROM work GROUP BY count;") do
      {:ok, [%{"result" => [%{"count" => count}]}]} ->
        {:ok, count}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def find(limit \\ nil, offset \\ nil, filter \\ nil) do
    limit = limit || 10
    filter = filter || %{}

    where = Utils.map_to_filter(filter)

    page =
      if limit != nil and offset != nil do
        "LIMIT #{limit} START #{offset}"
      else
        ""
      end

    clause =
      [where, page]
      |> Enum.join(" ")

    clause = if clause == "", do: "", else: " #{clause}"

    query = "SELECT * FROM work#{clause};"

    Log.debug(query)

    case Client.query("test", "work", query) do
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

  def insert(%ExStorage.Domain.Work{} = work) do
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
