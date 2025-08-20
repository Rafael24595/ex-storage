defmodule ExStorage.TUI.Screens.Utils do
  def decrement_cursor(cursor, options) do
    cursor = cursor || 0
    options = options || []

    if cursor - 1 < 0 do
      length(options) - 1
    else
      cursor - 1
    end
  end

  def increment_cursor(cursor, options) do
    cursor = cursor || 0
    options = options || []

    if cursor + 1 > length(options) - 1 do
      0
    else
      cursor + 1
    end
  end
end
