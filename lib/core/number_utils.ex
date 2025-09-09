defmodule ExStorage.Core.NumberUtils do
  @moduledoc """
  Utility functions for safety parse values into number type.
  """

  def integer_parse(str) do
    case Integer.parse(str) do
      {int, ""} -> {:ok, int}
      _ -> :error
    end
  end

  def integer_parse(str, _default) when is_integer(str) do
    {:ok, str}
  end

  def integer_parse(str, default) when is_integer(default) do
    case Integer.parse(str) do
      {int, ""} -> {:ok, int}
      _ -> {:ok, default}
    end
  end

  def integer_parse(str, _default) do
    case Integer.parse(str) do
      {int, ""} -> {:ok, int}
      _ -> :error
    end
  end
end
