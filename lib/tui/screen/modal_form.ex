defmodule ExStorage.TUI.Screens.ModalForm do
  @behaviour ExStorage.TUI.Screen

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
        "#{t}#{v}"
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

    commands = [
      {"s", "save"},
      {"c", "cancel"},
      {"q", "quit"}
    ]

    ExStorage.TUI.Screens.Modules.commands(commands)
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
        "list" ->
          format_list_value(f, value)

        _ ->
          format_text_value(f, value)
      end
    end)
  end

  def format_list_value(field, value) do
    position = list_value_index(field, value)

    ExStorage.TUI.Screens.Formatter.list_preview(field.values, position, 2)
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

    if select do
      {:same, state}
    else
      cursor = Map.get(state, :cursor)
      fields = Map.get(state, :fields)

      new_cursor = ExStorage.TUI.Screens.Utils.decrement_cursor(cursor, fields)

      {:same, Map.put(state, :cursor, new_cursor)}
    end
  end

  def handle_event(state, :down) do
    select = Map.get(state, :select, false)

    if select do
      {:same, state}
    else
      cursor = Map.get(state, :cursor)
      fields = Map.get(state, :fields)

      new_cursor = ExStorage.TUI.Screens.Utils.increment_cursor(cursor, fields)

      {:same, Map.put(state, :cursor, new_cursor)}
    end
  end

  def handle_event(state, :left) do
    manage_list(state, &ExStorage.TUI.Screens.Utils.decrement_cursor/2)
  end

  def handle_event(state, :right) do
    manage_list(state, &ExStorage.TUI.Screens.Utils.increment_cursor/2)
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

  def handle_event(state, {:char, "q"}) do
    select = Map.get(state, :select, false)

    if select do
      manage_text(state, "q")
    else
      {:quit, state}
    end
  end

  def handle_event(state, {:char, text}) do
    manage_text(state, text)
  end

  def handle_event(state, _) do
    {:keep, state}
  end

  def manage_list(state, mod_func) do
    select = Map.get(state, :select, false)

    if !select do
      {:same, state}
    else
      cursor = Map.get(state, :cursor, 0)
      fields = Map.get(state, :fields)
      field = Enum.at(fields, cursor)

      if "list" != field_type(field) do
        {:same, state}
      else
        values = Map.get(state, :values, %{})
        value = Map.get(values, field.code)

        position = list_value_index(field, value)

        new_cursor = mod_func.(position, field.values)

        value = %{
          code: field.code,
          value: new_cursor
        }

        values = Map.put(values, field.code, value)

        {:same, Map.put(state, :values, values)}
      end
    end
  end

  def manage_text(state, text) do
    select = Map.get(state, :select, false)

    if !select do
      {:same, state}
    else
      cursor = Map.get(state, :cursor, 0)
      fields = Map.get(state, :fields)
      field = Enum.at(fields, cursor)

      if "list" == field_type(field) do
        manage_text_as_list_item(state, field, text)
      else
        manage_text_as_string(state, field, text)
      end
    end
  end

  def manage_text_as_list_item(state, field, text) do
    Log.debug("#{inspect(field.values)} - #{text}")
    index = Enum.find_index(field.values, fn v -> v == text end)
    Log.debug("#{index}")

    if index != nil do
      values = Map.get(state, :values, %{})

      value = %{
        code: field.code,
        value: index
      }

      values = Map.put(values, field.code, value)

      {:same, Map.put(state, :values, values)}
    else
      {:same, state}
    end
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

  def list_value_index(field, value) do
    cond do
      value == nil || value.value == nil ->
        default = Map.get(field, :default)

        content =
          if default == nil do
            hd(field.values)
          else
            default
          end

        index =
          field.values
          |> Enum.find_index(fn v -> v == content end)

        if index != nil do
          index
        else
          0
        end

      is_number(value.value) ->
        value.value

      true ->
        0
    end
  end

  def field_type(field) do
    if field == nil || field.type == nil do
      "string"
    else
      field.type
    end
  end
end
