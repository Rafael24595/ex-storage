defmodule ExStorage.TUI.Screens.ModalForm do
  @behaviour ExStorage.TUI.Screen

  alias ExStorage.Core.Utils

  @impl true
  def onload(state) do
    render(state)
  end

  @impl true
  def render(state) do
    title = Map.get(state, :title, "Create item")

    titles = format_titles(state)
    values = format_values(state)

    rows =
      Enum.zip(titles, values)
      |> Enum.map(fn {t, v} ->
        "#{t}#{v}   "
      end)

    max_len =
      rows
      |> Enum.map(&String.length/1)
      |> Enum.max()

    max_len = max(max_len, String.length(title))

    title = ExStorage.TUI.Screens.Formatter.center_text(title, max_len)
    title = "| #{title} |"

    limit = String.duplicate("-", max_len + 4)
    IO.puts(limit)
    IO.puts(title)
    IO.puts(limit)

    rows
    |> Enum.each(fn r ->
      IO.puts("| #{String.pad_trailing(r, max_len)} |")
    end)

    IO.puts(limit)

    options = Map.get(state, :options)

    ExStorage.TUI.Screens.Modules.commands(options)
  end

  def format_titles(state) do
    fields = Map.get(state, :fields)
    cursor = Map.get(state, :cursor, 0)
    select = Map.get(state, :select, false)

    max_len =
      fields
      |> Enum.map(fn f -> f.title end)
      |> Enum.map(&String.length/1)
      |> Enum.max()

    fields
    |> Enum.with_index()
    |> Enum.map(fn {f, i} ->
      mark =
        cond do
          cursor == i && !select ->
            ">"

          cursor == i && select ->
            "#"

          true ->
            " "
        end

      title = String.pad_trailing(f.title, max_len)
      "#{mark} #{title}:   "
    end)
  end

  def format_values(state) do
    fields = Map.get(state, :fields)
    values = Map.get(state, :values, %{})

    fields
    |> Enum.map(fn f ->
      code = f.code
      type = f.type

      value = Map.get(values, code)

      case type do
        "enum" ->
          format_enum_value(f, value)

        "list" ->
          format_list_value(f, value)

        _ ->
          format_text_value(f, value)
      end
    end)
  end

  def format_enum_value(field, value) do
    values = list_or_default(field, value)
    position = list_value_index(field, values, value)

    ExStorage.TUI.Screens.Formatter.list_preview(values, position, %{
      radius: 2,
      start_char: "|",
      close_char: "|"
    })
  end

  def format_list_value(field, value) do
    values = list_or_default(field, value)
    position = list_value_index(field, values, value)

    ExStorage.TUI.Screens.Formatter.list_preview(values, position, %{
      radius: 2,
      start_char: "[",
      close_char: "]"
    })
  end

  def format_text_value(field, value) do
    max = Map.get(field, :max, 32)

    cond do
      value == nil || value.value == nil ->
        String.duplicate(".", max)

      true ->
        String.pad_trailing(value.value, max)
    end
  end

  @impl true
  def handle_event(state, :up) do
    select = Map.get(state, :select, false)
    move_cursor(state, :up, select)
  end

  def handle_event(state, :down) do
    select = Map.get(state, :select, false)
    move_cursor(state, :down, select)
  end

  def handle_event(state, :left) do
    select = Map.get(state, :select, false)
    list_navigate(state, &Utils.decrease_cursor/2, select)
  end

  def handle_event(state, :right) do
    select = Map.get(state, :select, false)
    list_navigate(state, &Utils.increase_cursor/2, select)
  end

  def handle_event(state, :enter) do
    select = !Map.get(state, :select, false)

    if select do
      Terminal.disable_raw_mode()
    else
      Terminal.enable_raw_mode()
    end

    {:same, Map.put(state, :select, select)}
  end

  def handle_event(state, {:char, text}) do
    select = Map.get(state, :select, false)
    manage_option(state, text, select)
  end

  def handle_event(state, _) do
    {:keep, state}
  end

   defp move_cursor(state, :up, false) do
    cursor = Map.get(state, :cursor)
    fields = Map.get(state, :fields)

    new_cursor = Utils.decrease_cursor(cursor, fields)

    {:same, Map.put(state, :cursor, new_cursor)}
  end

  defp move_cursor(state, :up, true) do
    {:same, state}
  end

  defp move_cursor(state, :down, false) do
    cursor = Map.get(state, :cursor)
    fields = Map.get(state, :fields)

    new_cursor = Utils.increase_cursor(cursor, fields)

    {:same, Map.put(state, :cursor, new_cursor)}
  end

  defp move_cursor(state, :down, true) do
    {:same, state}
  end

  defp manage_option(state, text, false) do
    options = Map.get(state, :options)
    cursor = Enum.find_index(options, fn {c, _, _} -> c == text end)
    execute_option(state, text, cursor)
  end

  defp manage_option(state, text, true) do
    cursor = Map.get(state, :cursor, 0)
    fields = Map.get(state, :fields)
    field = Enum.at(fields, cursor)

    case field_type(field) do
      "enum" ->
        manage_text_as_enum_item(state, field, text)

      "list" ->
        manage_text_as_list_action(state, field, text)

      _ ->
        manage_text_as_string(state, field, text)
    end
  end

  defp list_navigate(state, _mod_func, false) do
    {:same, state}
  end

  defp list_navigate(state, mod_func, true) do
    cursor = Map.get(state, :cursor, 0)
    fields = Map.get(state, :fields)
    field = Enum.at(fields, cursor)

    case field_type(field) do
      type when type not in ["enum", "list"] ->
        {:same, state}

      _ ->
        values = Map.get(state, :values, %{})
        value = Map.get(values, field.code, %{})

        list = list_or_default(field, value)
        position = list_value_index(field, list, value)

        new_cursor = mod_func.(position, list)

        value =
          value
          |> Map.put(:code, field.code)
          |> Map.put(:cursor, new_cursor)

        values = Map.put(values, field.code, value)

        {:same, Map.put(state, :values, values)}
    end
  end

  def execute_option(state, char, nil) do
    fields = Map.get(state, :fields)

    new_cursor =
      fields
      |> Enum.find_index(fn f -> Utils.equal_ignore_case?(f.title, char) end)

    if new_cursor != nil do
      {:same, Map.put(state, :cursor, new_cursor)}
    else
      {:same, state}
    end
  end

  def execute_option(state, _char, cursor) do
    options = Map.get(state, :options)
    {_, _, func} = Enum.at(options, cursor)
    func.(state)
  end

  def manage_text_as_enum_item(state, field, text) do
    index = Enum.find_index(field.values, fn v -> v == text end)

    if index != nil do
      values = Map.get(state, :values, %{})

      value = %{
        code: field.code,
        cursor: index
      }

      values = Map.put(values, field.code, value)

      {:same, Map.put(state, :values, values)}
    else
      {:same, state}
    end
  end

  def manage_text_as_list_action(state, field, text) do
    # TODO
    {first, rest} = String.next_grapheme(text)
    rest = String.trim(rest)

    case first do
      "\\" ->
        {first, rest} = String.next_grapheme(rest)
        rest = String.trim(rest)

        case first do
          "d" ->
            delete_list(state, field, rest)

          "h" ->
            Log.debug("head")

          "t" ->
            Log.debug("tail")

          "r" ->
            Log.debug("replace")

          _ ->
            define_list(state, field, rest)
        end

      _ ->
        define_list(state, field, text)
    end
  end

  defp delete_list(state, field, "*") do
    values = Map.get(state, :values, %{})
    values = Map.delete(values, field.code)
    {:same, state |> Map.put(:values, values) |> Map.put(:select, false)}
  end

  defp delete_list(state, field, text) do
    values = Map.get(state, :values, %{})

    case Map.get(values, field.code) do
      nil ->
        {:same, Map.put(state, :values, values)}

      value ->
        {list, index} = update_list_and_index(value, field, text)

        index = max(index - 1, 0)

        value = %{
          code: field.code,
          cursor: index,
          value: list
        }

        values = Map.put(values, field.code, value)
        {:same, Map.put(state, :values, values)}
    end
  end

  defp update_list_and_index(value, field, "") do
    list = Map.get(value, :value, [])
    index = list_value_index(field, list, value)
    {List.delete_at(list, index), index}
  end

  defp update_list_and_index(value, _field, text) do
    list = Map.get(value, :value, [])

    case Enum.find_index(list, fn t -> t == text end) do
      nil ->
        index = Map.get(value, :cursor, 0)
        {list, index}

      index ->
        {List.delete_at(list, index), index}
    end
  end

  defp define_list(state, field, text) do
    values = Map.get(state, :values, %{})
    list = text_to_list(text)

    values =
      cond do
        length(list) == 0 ->
          Map.delete(values, field.code)

        true ->
          value = %{
            code: field.code,
            value: list
          }

          Map.put(values, field.code, value)
      end

    {:same, state |> Map.put(:values, values) |> Map.put(:select, false)}
  end

  defp text_to_list(text) do
    text
    |> String.split(" ")
    |> Enum.filter(fn t -> t != "" end)
    |> Enum.map(&String.trim/1)
  end

  defp manage_text_as_string(state, field, text) do
    values = Map.get(state, :values, %{})

    values =
      if text == "" do
        Map.delete(values, field.code)
      else
        value = %{
          code: field.code,
          value: text
        }

        Map.put(values, field.code, value)
      end

    state = Map.put(state, :select, false)
    {:same, Map.put(state, :values, values)}
  end

  def list_value_index(field, values, value) do
    cursor = Map.get(value || %{}, :cursor)

    case cursor do
      nil ->
        search_default_index(field, values)

      cursor when is_number(cursor) ->
        cursor

      _ ->
        0
    end
  end

  def search_default_index(field, values) do
    content = Map.get(field, :default) || List.first(values, "")
    Enum.find_index(values, fn v -> v == content end) || 0
  end

  def list_or_default(%{type: "list"} = field, value) do
    Map.get(value || %{}, :value) || Map.get(field, :values, [])
  end

  def list_or_default(%{type: "enum"} = field, _value) do
    Map.get(field, :values, [])
  end

  def field_type(field) do
    Map.get(field || %{}, :type, "string")
  end
end
