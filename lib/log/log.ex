defmodule Log do
  def info(msg), do: ExStorage.Log.Logger.info(msg)
  def erro(msg), do: ExStorage.Log.Logger.erro(msg)
  def warn(msg), do: ExStorage.Log.Logger.warn(msg)
end
