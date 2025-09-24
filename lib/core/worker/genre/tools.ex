defmodule ExStorage.Core.Worker.GenreTools do
  alias ExStorage.Core.Worker.GenreService
  alias ExStorage.Core.Worker.StateServer

  def items do
    case StateServer.find(GenreService.pid()) do
      {:ok, items} ->
        items

      {:error, reason} ->
        Log.error("#{reason}")
        []
    end
  end
end
