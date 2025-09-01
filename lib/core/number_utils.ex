defmodule ExStorage.Core.NumberUtils do
  def integer_parse(str) do
    case Integer.parse(str) do
      {int, ""} -> {:ok, int}
      _ -> :error
    end
  end

  def integer_parse(str, default) when is_integer(default) do
    case Integer.parse(str) do
      {int, ""} -> {:ok, int}
      _ -> default
    end
  end

  def integer_parse(str, _default) do
    case Integer.parse(str) do
      {int, ""} -> {:ok, int}
      _ -> :error
    end
  end
end
