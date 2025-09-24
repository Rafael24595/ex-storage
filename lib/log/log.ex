defmodule Log do
  alias ExStorage.Log.Logger

  def info(message, references \\ []), do: Logger.info(message, references)
  def warn(message, references \\ []), do: Logger.warn(message, references)
  def error(message, cause \\ nil, references \\ []), do: Logger.error(message, cause, references)
  def debug(any), do: Logger.debug(any)
end
