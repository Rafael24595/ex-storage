defmodule NumberUtils do
  def integer_parse(str) do
    case Integer.parse(str) do
      {int, ""} -> {:ok, int}
      _ -> :error
    end
  end

  def integer_parse(str, def) do
    with {int, ""} <- Integer.parse(str) do
      {:ok, int}
    else
      _ when is_integer(def) -> def
      _ -> :error
    end
  end
end
