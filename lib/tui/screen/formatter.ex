defmodule ExStorage.TUI.Screens.Formatter do

  def format_table(columns) do
    fixed_columns =
      Enum.map(columns, fn {h, v} ->
        format_column(h, v)
      end)

    headers =
      fixed_columns
      |> Enum.map(fn {:head, h, :values, _v} -> h end)
      |> format_row()

    rows =
      fixed_columns
      |> Enum.map(fn {:head, _h, :values, v} -> v end)
      |> Enum.zip()
      |> Enum.map(&Tuple.to_list/1)
      |> Enum.map(&format_row/1)

    {:headers, headers, :rows, rows}
  end

  defp format_row(row) do
      (row
      |> Enum.map(&"| #{&1} ")
      |> Enum.join())
      <>("|")
  end

  defp format_column(head, values) do
    max_length =
      values
      |> Enum.map(&String.length/1)
      |> Enum.max()

    max_length = max(max_length, String.length(head))

    head = format_cell(head, max_length)
    values = Enum.map(values, fn v ->
      format_cell(v, max_length)
    end)

    {:head, head, :values, values}
  end

  defp format_cell(value, max_length) do
    value_len = String.length(value)

    value = if value_len < max_length do
      fix = String.duplicate(" ", max_length - value_len)
      "#{value}#{fix}"
    else
      value
    end

    "#{value}"
  end

end
