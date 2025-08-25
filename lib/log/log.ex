defmodule Log do
  def info(message), do: ExStorage.Log.Logger.info(message)
  def warn(message), do: ExStorage.Log.Logger.warn(message)
  def error(message), do: ExStorage.Log.Logger.error(message)
  def error(message, cause), do: ExStorage.Log.Logger.error(message, cause)
  def debug(message), do: ExStorage.Log.Logger.debug(message)
end
