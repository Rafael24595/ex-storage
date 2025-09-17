defmodule ExStorage.Core.Worker.Service do
  @callback fetch(state :: map(), offset :: any()) ::
              {:ok, map()} | {:error, map(), any()}
end
