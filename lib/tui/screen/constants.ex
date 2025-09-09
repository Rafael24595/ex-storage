defmodule ExStorage.TUI.Screen.Constants do
  @moduledoc """
  Static resources used across TUI modules.
  """

  def items_table_help(custom_overview \\ nil, custom_controls \\ nil) do
    overview = [
      "Screen Overview:",
      {"(xxx)", "Total number of items. If shown as (xxx/xxx), a filter is applied."},
      {"[xxx-yyy]", "Range of items currently displayed."},
      {"›", "Cursor indicating the selected item."}
    ]

    controls = [
      "Controls:",
      {"↑ / ↓", "Move between works on the current page."},
      {"← / →", "Move between different work pages."},
      {"number", "Type an index to move the cursor to that work."}
    ]

    overview
    |> Enum.concat(custom_overview || [])
    |> Enum.concat(["\n"])
    |> Enum.concat(controls)
    |> Enum.concat(custom_controls || [])
    |> Enum.concat(["\n"])
  end

  def filter_help do
    [
      "Filter help",
      {"text*", "If a string ends with *, it means it starts with the specified value"},
      {"*text", "If a string starts with *, it means it ends with the specified value"},
      {"*text*", "If a string is surrounded by *, it means it contains the specified value"},
      {"<", "If a value starts with <, it means greater than the specified value"},
      {"<=", "If a value starts with <=, it means greater than or equal to the specified value"},
      {">", "If a value starts with >, it means less than the specified value"},
      {">=", "If a value starts with >=, it means less than or equal to the specified value"},
      {"number-number", "If two numeric values contais a - between then, it means range between values"},
      "\n"
    ]
  end
end
