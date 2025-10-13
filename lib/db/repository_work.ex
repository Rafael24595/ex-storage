defmodule ExStorage.DB.RepositoryWork do
  @moduledoc """
  Behaviour definition for work repositories in ExStorage.

  Any module that implements this behaviour is responsible for persisting and
  retrieving `ExStorage.Domain.WorkV1` entities. This abstraction allows multiple
  backends (e.g., in-memory, database, external services) to be used
  interchangeably.

  ## Callbacks

    * `count/0` — Returns the total number of works.
    * `find/2` — Retrieves a paginated list of works given a `limit` and `offset`.
    * `insert/1` — Persists a new work item.
    * `delete/1` — Deletes a work item by its ID.
  """
alias ExStorage.Domain.WorkV1

  @callback count() ::
              {:ok, integer()}
              | {:error, any()}
  @callback count_filter(filter :: map() | nil) ::
              {:ok, integer() | nil}
              | {:error, any()}
  @callback find(limit :: integer() | nil, offset :: integer() | nil, filter :: map() | nil) ::
              {:ok, list(WorkV1.t())}
              | {:error, any()}
  @callback insert(work :: WorkV1.t()) ::
              {:ok, list(WorkV1.t())}
              | {:error, any()}
  @callback delete(id :: String.t() | nil) ::
              {:ok, WorkV1.t() | nil}
              | {:error, any()}
end
