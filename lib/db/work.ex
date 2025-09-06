defmodule ExStorage.DB.Work do
  @moduledoc """
  Behaviour definition for work repositories in ExStorage.

  Any module that implements this behaviour is responsible for persisting and
  retrieving `ExStorage.Domain.Work` entities. This abstraction allows multiple
  backends (e.g., in-memory, database, external services) to be used
  interchangeably.

  ## Callbacks

    * `count/0` — Returns the total number of works.
    * `find/2` — Retrieves a paginated list of works given a `limit` and `offset`.
    * `insert/1` — Persists a new work item.
    * `delete/1` — Deletes a work item by its ID.
  """

  @callback count() ::
              {:ok, integer()}
              | {:error, any()}
  @callback find(limit :: integer() | nil, offset :: integer() | nil) ::
              {:ok, list(ExStorage.Domain.Work.t())}
              | {:error, any()}
  @callback insert(work :: ExStorage.Domain.Work.t()) ::
              {:ok, list(ExStorage.Domain.Work.t())}
              | {:error, any()}
  @callback delete(id :: String.t() | nil) ::
              {:ok, ExStorage.Domain.Work.t() | nil}
              | {:error, any()}
end
