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
     |> Enum.join()) <>
      "|"
  end

  defp format_column(head, values) do
    max_length =
      values
      |> Enum.map(&String.length/1)
      |> Enum.max()

    max_length = max(max_length, String.length(head))

    head = format_cell(head, max_length)

    values =
      Enum.map(values, fn v ->
        format_cell(v, max_length)
      end)

    {:head, head, :values, values}
  end

  defp format_cell(value, max_length) do
    value_len = String.length(value)

    value =
      if value_len < max_length do
        fix = String.duplicate(" ", max_length - value_len)
        "#{value}#{fix}"
      else
        value
      end

    "#{value}"
  end

  def center_text(text, max_width) do
    mid_with = div(max_width + String.length(text), 2)
    text = String.pad_leading(text, mid_with)
    String.pad_trailing(text, max_width)
  end

  def list_preview(list, cursor, opts) do
    start_char = Map.get(opts, :start_char, "|")
    close_char = Map.get(opts, :close_char, "|")
    point_char = Map.get(opts, :point_char, "^")
    points = Map.get(opts, :points, [])

    len = length(list)

    {from, to} = calculate_area(list, cursor, opts)

    if to < 0 do
      "#0 #{start_char} ... #{close_char}"
    else
      slice = Enum.slice(list, from..to)

      max_len =
        list
        |> Enum.map(&String.length/1)
        |> Enum.max()

      preview =
        slice
        |> Enum.with_index(from)
        |> Enum.map(fn {item, idx} ->
          point = if idx in points, do: "#{point_char}", else: " "
          item = "#{point}#{item}#{point}"
          item = " #{center_text(item, max_len)} "
          Log.debug(item)
          if idx == cursor, do: " {#{item}} ", else: item
        end)
        |> Enum.join("|")

      left = if from > 0, do: "<", else: start_char
      right = if to < len - 1, do: ">", else: close_char

      "##{length(list)} #{left}#{preview}#{right}"
    end
  end

  defp calculate_area(list, cursor, opts) do
    radius = Map.get(opts, :radius, 2)

    len = length(list)
    last = len - 1

    mid = trunc(radius / 2)

    init_from = cursor - mid
    init_to = cursor + mid

    {from, to} =
      if init_from < 0 do
        shift = -init_from
        {0, min(last, init_to + shift)}
      else
        {init_from, init_to}
      end

    if to > last do
      shift = to - last
      {max(0, from - shift), last}
    else
      {from, to}
    end
  end
end
