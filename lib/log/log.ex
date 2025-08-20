defmodule Log do
  def info(msg), do: ExStorage.Log.Logger.info(msg)
  def warn(msg), do: ExStorage.Log.Logger.warn(msg)
  def error(msg), do: ExStorage.Log.Logger.error(msg)
  def debug(msg), do: ExStorage.Log.Logger.debug(msg)
end
