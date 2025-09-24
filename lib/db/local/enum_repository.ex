defmodule ExStorage.DB.Local.EnumRepository do
  alias ExStorage.Core.FileUtils
  alias ExStorage.Core.Utils
  alias ExStorage.DB.Local.EnumState

  def init(%{name: name, file: file, parser: parser}) do
    items =
      case FileUtils.read_json(file, parser) do
        {:ok, result} ->
          result

        {:error, reason} ->
          Log.error("Error during '#{name}' module initialization", reason)
          []
      end

    state = EnumState.new_state(file, items)
    {:ok, state}
  end

  def count(state) do
    count =
      state
      |> Map.get(:items, [])
      |> Enum.count()

    {:reply, {:ok, count}, state}
  end

  def count_filter(state, nil) do
    {:reply, {:ok, nil}, state}
  end

  def count_filter(state, filter) do
    count =
      state
      |> filter_items(filter)
      |> Enum.count()

    {:reply, {:ok, count}, state}
  end

  def find(state, nil, nil, nil) do
    items = Map.get(state, :items, [])
    {:reply, {:ok, items}, state}
  end

  def find(state, limit, offset, nil) do
    items =
      state
      |> Map.get(:items, [])
      |> Enum.slice(offset, limit)

    {:reply, {:ok, items}, state}
  end

  def find(state, limit, offset, filter) do
    items =
      state
      |> filter_items(filter)
      |> Enum.slice(offset, limit)

    {:reply, {:ok, items}, state}
  end

  defp filter_items(state, filter) do
    items = Map.get(state, :items, [])
    pattern = Map.get(filter, :code, "")

    cond do
      pattern == "" ->
        items

      String.contains?(pattern, "*") ->
        regex = Utils.pattern_to_regex(pattern)

        Enum.filter(items, fn v ->
          Regex.match?(regex, String.downcase(v))
        end)
    end
  end
end
