defmodule ExStorage.TUI.Screens.ModalForm do
  @behaviour ExStorage.TUI.Screen

  alias ExStorage.Core.Utils

  @def_max_text 64

  def new_state(message, fields, options, values \\ nil, cursor \\ nil) do
    %{
      show_help: false,
      title: message,
      fields: fields,
      options: options,
      values: values || %{},
      cursor: cursor || 0
    }
  end

  @impl true
  def onload(state) do
    render(state)
  end

  @impl true
  def render(%{show_help: true} = _state) do
    actions = [
      "Form",
      {"↑ / ↓", "Navigate between form fields."},
      {"text",
       "Type the name of an field (ignore case) to move the cursor. Use '*' as a wildcard for any characters."},
      {"enter",
       "Fix the cursor to the field to interact with it, or release if already selected."},
      "\n",
      "Text input -> ...",
      {"text", "Type the value."},
      "\n",
      "Date input -> yyyy-mm-dd hh:mm:ss",
      {"now", "Sets the current date in ISO-8601 format."},
      {"text", "Type the date with ISO-8601 format: yyyy-mm-dd or yyyy-mm-dd hh:mm:ss."},
      "\n",
      "List input -> [ ... ]",
      {"← / →", "Move between list items."},
      {"text", "Type the values separated by space."},
      {"\\f",
       "Type the name of an item (ignore case) to move the cursor. Use '*' as a wildcard for any characters."},
      {"\\d", "If '*' added, clear the list; otherwise delete focused item."},
      {"\\h", "Append items to head."},
      {"\\t", "Append items to tail."},
      {"\\c", "Append items after cursor."},
      {"\\r", "Append items at cursor position, replacing it."},
      "\n",
      "Enum input -> | ... |",
      {"← / →", "Move between enum items."},
      {"text",
       "Type the name of an item (ignore case) to move the cursor. Use '*' as a wildcard for any characters."},
      {"\\f",
       "Type the name of an item (ignore case) to move the cursor. Use '*' as a wildcard for any characters."},
      {"\\d",
       "Delete the focused item; if the field is required, the first element will be selected."},
      "Tally input -> ( ... )",
      {"← / →", "Move between tally items."},
      {"\\f",
       "Type the name of an item (ignore case) to move the cursor. Use '*' as a wildcard for any characters."},
      {"\\s", "If '*' added, select all itmes; otherwise select the focused item (it will appear with dashes, e.g. -item-)."},
      {"\\d", "If '*' added, clear the selection; otherwise delete focused item."},
      "\n"
    ]

    commands = [
      {"c", "continue"},
      {"q", "quit"}
    ]

    ExStorage.TUI.Screens.Modules.help(actions)
    ExStorage.TUI.Screens.Modules.commands(commands)
  end

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

    options = [{"h", "help"} | Map.get(state, :options, [])]

    ExStorage.TUI.Screens.Modules.commands(options)
  end

  defp format_titles(state) do
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

  defp format_values(state) do
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

        "tally" ->
          format_tally_value(f, value)

        "date" ->
          format_date_value(f, value)

        _ ->
          format_text_value(f, value)
      end
    end)
  end

  defp format_enum_value(field, value) do
    values = list_or_default(field, value)
    position = list_index_or_default(field, values, value)

    ExStorage.TUI.Screens.Formatter.list_preview(values, position, %{
      radius: 2,
      start_char: "|",
      close_char: "|"
    })
  end

  defp format_list_value(field, value) do
    values = list_or_default(field, value)
    position = list_index_or_default(field, values, value)

    ExStorage.TUI.Screens.Formatter.list_preview(values, position, %{
      radius: 2,
      start_char: "[",
      close_char: "]"
    })
  end

  defp format_tally_value(field, value) do
    values = list_or_default(field, value)
    position = tally_index_or_default(field, value)
    points = Map.get(value || %{}, :value, [])

    ExStorage.TUI.Screens.Formatter.list_preview(values, position, %{
      radius: 2,
      start_char: "(",
      close_char: ")",
      point_char: "-",
      points: points
    })
  end

  defp format_date_value(field, value) do
    value = Map.get(value || %{}, :value) || Map.get(field, :default)

    case value do
      millis when is_integer(millis) ->
        ExStorage.Core.DateUtils.from_millis(millis)

      nil ->
        ExStorage.Core.DateUtils.date_pattern()
    end
  end

  defp format_text_value(field, value) do
    max = Map.get(field, :max, @def_max_text)

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

  def handle_event(%{show_help: false} = state, {:char, "h"}) do
    state = Map.put(state, :show_help, true)
    {:same, state}
  end

  def handle_event(%{show_help: true} = state, {:char, "c"}) do
    state = Map.put(state, :show_help, false)
    {:same, state}
  end

  def handle_event(state, {:char, text}) do
    select = Map.get(state, :select, false)
    manage_option(state, text, select)
  end

  def handle_event(state, _) do
    {:same, state}
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

      "tally" ->
        manage_text_as_tally_action(state, field, text)

      "date" ->
        manage_text_as_date(state, field, text)

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
      type when type not in ["enum", "list", "tally"] ->
        {:same, state}

      _ ->
        values = Map.get(state, :values, %{})
        value = Map.get(values, field.code, %{})

        list = list_or_default(field, value)
        position = list_index_or_default(field, list, value)

        new_cursor = mod_func.(position, list)

        value =
          value
          |> Map.put(:code, field.code)
          |> Map.put(:cursor, new_cursor)

        values = Map.put(values, field.code, value)

        {:same, Map.put(state, :values, values)}
    end
  end

  defp execute_option(state, text, nil) do
    fields = Map.get(state, :fields)

    extractor = fn f -> f.title end

    case Utils.match_index(fields, text, extractor) do
      nil ->
        {:same, state}

      cursor ->
        {:same, Map.put(state, :cursor, cursor)}
    end
  end

  defp execute_option(state, _char, cursor) do
    options = Map.get(state, :options)
    {_, _, func} = Enum.at(options, cursor)
    func.(state)
  end

  defp manage_text_as_enum_item(state, field, text) do
    case Utils.parse_command(text) do
      {:cmd, "f", rest} ->
        find_enum(state, field, rest)

      {:cmd, "d", _rest} ->
        delete_enum(state, field)

      {:cmd, _, _rest} ->
        {:same, state}

      {:text, text} ->
        find_enum(state, field, text)
    end
  end

  defp find_enum(state, field, text) do
    extractor = fn f -> f end

    case Utils.match_index(field.values, text, extractor) do
      nil ->
        {:same, state}

      cursor ->
        values = Map.get(state, :values, %{})

        value =
          values
          |> Map.get(field.code, %{})
          |> Map.put(:code, field.code)
          |> Map.put(:cursor, cursor)

        values = Map.put(values, field.code, value)

        {:same, Map.put(state, :values, values)}
    end
  end

  defp delete_enum(state, field) do
    values = Map.get(state, :values, %{})
    values = Map.delete(values, field.code)
    {:same, state |> Map.put(:values, values) |> Map.put(:select, false)}
  end

  defp manage_text_as_list_action(state, field, text) do
    case Utils.parse_command(text) do
      {:cmd, "f", rest} ->
        find_list(state, field, rest)

      {:cmd, "d", rest} ->
        delete_list(state, field, rest)

      {:cmd, "h", rest} ->
        append_to_list(state, field, rest, :head)

      {:cmd, "t", rest} ->
        append_to_list(state, field, rest, :tail)

      {:cmd, "c", rest} ->
        append_to_list(state, field, rest, :cursor)

      {:cmd, "r", rest} ->
        append_to_list(state, field, rest, :replace)

      {:cmd, _, rest} ->
        list = text_to_list(rest)
        define_list(state, field, list)

      {:text, text} ->
        list = text_to_list(text)
        define_list(state, field, list)
    end
  end

  defp find_list(state, field, text) do
    values = Map.get(state, :values, %{})

    list =
      values
      |> Map.get(field.code, %{})
      |> Map.get(:value, [])

    extractor = fn f -> f end

    case Utils.match_index(list, text, extractor) do
      nil ->
        {:same, state}

      cursor ->
        value = %{
          code: field.code,
          cursor: cursor,
          value: list
        }

        values = Map.put(values, field.code, value)
        {:same, Map.put(state, :values, values)}
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
    index = list_index_or_default(field, list, value)
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

  defp define_list(state, field, []) do
    values =
      state
      |> Map.get(:values, %{})
      |> Map.delete(field.code)

    {:same, state |> Map.put(:values, values) |> Map.put(:select, false)}
  end

  defp define_list(state, field, list) do
    value = %{
      code: field.code,
      value: list
    }

    values =
      state
      |> Map.get(:values, %{})
      |> Map.put(field.code, value)

    {:same, state |> Map.put(:values, values) |> Map.put(:select, false)}
  end

  defp append_to_list(state, field, text, :head) do
    current =
      state
      |> Map.get(:values, %{})
      |> Map.get(field.code, %{})
      |> Map.get(:value, [])

    list =
      text
      |> text_to_list()
      |> Enum.concat(current)

    define_list(state, field, list)
  end

  defp append_to_list(state, field, text, :tail) do
    list =
      state
      |> Map.get(:values, %{})
      |> Map.get(field.code, %{})
      |> Map.get(:value, [])
      |> Enum.concat(text_to_list(text))

    define_list(state, field, list)
  end

  defp append_to_list(state, field, text, :cursor) do
    value =
      state
      |> Map.get(:values, %{})
      |> Map.get(field.code, %{})

    list = list_or_default(field, value)
    cursor = list_index_or_default(field, list, value)

    list = ListUtils.concat_at(list, text_to_list(text), cursor)

    define_list(state, field, list)
  end

  defp append_to_list(state, field, text, :replace) do
    value =
      state
      |> Map.get(:values, %{})
      |> Map.get(field.code, %{})

    list = list_or_default(field, value)
    cursor = list_index_or_default(field, list, value)

    list = ListUtils.replace_at(list, text_to_list(text), cursor)

    define_list(state, field, list)
  end

  defp text_to_list(text) do
    text
    |> String.split(" ")
    |> Enum.filter(fn t -> t != "" end)
    |> Enum.map(&String.trim/1)
  end

  defp manage_text_as_tally_action(state, field, text) do
    case Utils.parse_command(text) do
      {:cmd, "f", rest} ->
        find_enum(state, field, rest)

      {:cmd, "s", rest} ->
        select_tally(state, field, rest)

      {:cmd, "d", rest} ->
        delete_tally(state, field, rest)

      {:cmd, _, _rest} ->
        {:same, state}

      {:text, text} ->
        find_enum(state, field, text)
    end
  end

  defp select_tally(state, field, "*") do
    values = Map.get(state, :values, %{})

    value = Map.get(values, field.code, %{})
    items = Map.get(field, :values, [])

    last = max(length(items) - 1, 0)
    list = Enum.to_list(0..last)

    value =
      value
      |> Map.put(:value, list)
      |> Map.put(:cursor, 0)

    values = Map.put(values, field.code, value)

    {:same, state |> Map.put(:values, values)}
  end

  defp select_tally(state, field, _) do
    values = Map.get(state, :values, %{})

    value = Map.get(values, field.code, %{})
    list = Map.get(value, :value, [])

    cursor = list_index_or_default(field, list, value) || 0

    case Enum.find_index(list, fn v -> v == cursor end) do
      nil ->
        items = Map.get(field, :values, [])

        new_list =
          list
          |> Enum.concat([cursor])
          |> Utils.clean_pointers(items)

        value =
          value
          |> Map.put(:value, new_list)
          |> Map.put(:cursor, cursor)

        values = Map.put(values, field.code, value)

        {:same, state |> Map.put(:values, values)}

      _ ->
        {:same, state}
    end
  end

  defp delete_tally(state, field, "*") do
    delete_enum(state, field)
  end

  defp delete_tally(state, field, _text) do
    values = Map.get(state, :values, %{})

    case Map.get(values, field.code) do
      nil ->
        {:same, Map.put(state, :values, values)}

      value ->
        list = Map.get(value, :value, [])
        cursor = list_index_or_default(field, list, value)

        list =
          case Enum.find_index(list, fn v -> v == cursor end) do
            nil ->
              list

            index ->
              List.delete_at(list, index)
          end

        value = Map.put(value, :value, list)
        values = Map.put(values, field.code, value)
        {:same, Map.put(state, :values, values)}
    end
  end

  defp manage_text_as_date(state, field, text) do
    values = Map.get(state, :values, %{})

    values =
      case text do
        "" ->
          Map.delete(values, field.code)

        "now" ->
          now = DateTime.utc_now()

          value = %{
            code: field.code,
            value: DateTime.to_unix(now, :millisecond)
          }

          Map.put(values, field.code, value)

        other ->
          value = %{
            code: field.code,
            value: ExStorage.Core.DateUtils.to_millis(other)
          }

          Map.put(values, field.code, value)
      end

    state = Map.put(state, :select, false)
    {:same, Map.put(state, :values, values)}
  end

  defp manage_text_as_string(state, field, text) do
    values = Map.get(state, :values, %{})

    values =
      if text == "" do
        Map.delete(values, field.code)
      else
        len = String.length(text)
        max = Map.get(field, :max, @def_max_text)

        text = if len > max, do: String.slice(text, 0, max), else: text

        value = %{
          code: field.code,
          value: text
        }

        Map.put(values, field.code, value)
      end

    state = Map.put(state, :select, false)
    {:same, Map.put(state, :values, values)}
  end

  defp list_index_or_default(field, values, value) do
    cursor = Map.get(value || %{}, :cursor)
    required = Map.get(field, :required, false)

    cond do
      cursor == nil && required ->
        content = Map.get(field, :default) || List.first(values, "")
        Enum.find_index(values, fn v -> v == content end) || 0

      is_number(cursor) ->
        cursor

      true ->
        nil
    end
  end

  defp tally_index_or_default(field, value) do
    cursor = Map.get(value || %{}, :cursor)
    required = Map.get(field, :required, false)

    cond do
      cursor == nil && required ->
        0

      is_number(cursor) ->
        cursor

      true ->
        nil
    end
  end

  defp list_or_default(%{type: "list"} = field, value) do
    Map.get(value || %{}, :value) || Map.get(field, :values, [])
  end

  defp list_or_default(%{type: "enum"} = field, _value) do
    Map.get(field, :values, [])
  end

  defp list_or_default(%{type: "tally"} = field, _value) do
    Map.get(field, :values, [])
  end

  defp field_type(field) do
    Map.get(field || %{}, :type, "string")
  end
end
