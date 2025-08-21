defmodule ExStorage.Core.Utils do
  def decrease_cursor(cursor, options) do
    cursor = cursor || 0
    options = options || []

    if cursor - 1 < 0 do
      length(options) - 1
    else
      cursor - 1
    end
  end

  def increase_cursor(cursor, options) do
    cursor = cursor || 0
    options = options || []

    if cursor + 1 > length(options) - 1 do
      0
    else
      cursor + 1
    end
  end

  def equal_ignore_case?(a, b) do
    String.downcase(a) == String.downcase(b)
  end
end
