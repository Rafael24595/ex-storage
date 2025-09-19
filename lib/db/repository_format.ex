defmodule ExStorage.DB.RepositoryFormat do
  @callback count() ::
              {:ok, integer()}
              | {:error, any()}
  @callback count_filter(filter :: map() | nil) ::
              {:ok, integer() | nil}
              | {:error, any()}
  @callback find(limit :: integer() | nil, offset :: integer() | nil, filter :: map() | nil) ::
              {:ok, list(String.t())}
              | {:error, any()}
  @callback insert(work :: String.t()) ::
              {:ok, list(String.t())}
              | {:error, any()}
  @callback delete(id :: String.t() | nil) ::
              {:ok, String.t() | nil}
              | {:error, any()}
end
