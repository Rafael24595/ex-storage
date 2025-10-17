defmodule ExStorage.DB.RepositoryConcept do
  @moduledoc """
  Behaviour definition for concept repositories in ExStorage.

  Any module that implements this behaviour is responsible for persisting and
  retrieving `ConceptV1` entities. This abstraction allows multiple
  backends (e.g., in-memory, database, external services) to be used
  interchangeably.

  ## Callbacks

    * `count/0` — Returns the total number of concepts.
    * `find/2` — Retrieves a paginated list of concepts given a `limit` and `offset`.
    * `insert/1` — Persists a new concept item.
    * `delete/1` — Deletes a concept item by its ID.
  """
alias ExStorage.Domain.ConceptV1

  @callback count() ::
              {:ok, integer()}
              | {:error, any()}
  @callback count_filter(filter :: map() | nil) ::
              {:ok, integer() | nil}
              | {:error, any()}
  @callback find(limit :: integer() | nil, offset :: integer() | nil, filter :: map() | nil) ::
              {:ok, list(ConceptV1.t())}
              | {:error, any()}
  @callback insert(work :: ConceptV1.t()) ::
              {:ok, list(ConceptV1.t())}
              | {:error, any()}
  @callback delete(id :: String.t() | nil) ::
              {:ok, ConceptV1.t() | nil}
              | {:error, any()}
end
