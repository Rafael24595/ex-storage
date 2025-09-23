defmodule ExStorage.Core.Worker.FormatTools do
  alias ExStorage.Core.Worker.FormatService
  alias ExStorage.Core.Worker.StateServer

  def items do
    case StateServer.find(FormatService.pid()) do
      {:ok, items} ->
        items

      {:error, reason} ->
        Log.error("#{reason}")
        []
    end
  end
end
