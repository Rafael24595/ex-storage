defmodule ExStorage.DB.Work do
  @callback count() ::
              {:ok, integer()}
              | {:error, any()}
  @callback find(limit :: integer() | nil, offset :: integer() | nil) ::
              {:ok, list(ExStorage.Domain.Work.t())}
              | {:error, any()}
  @callback create(work :: ExStorage.Domain.Work.t()) ::
              {:ok, list(ExStorage.Domain.Work.t())}
              | {:error, any()}
end
