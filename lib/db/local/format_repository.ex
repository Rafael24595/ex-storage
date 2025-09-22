defmodule ExStorage.DB.Local.FormatRepository do
  @behaviour ExStorage.DB.RepositoryFormat

  use GenServer

  alias ExStorage.Core.FileUtils
  alias ExStorage.Core.Utils
  alias ExStorage.DB.Local.FormatState

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def init(_) do
    items =
      case FileUtils.read_json(
             "./db/format.json",
             &ExStorage.DB.Local.FormatRepository.parse_json/1
           ) do
        {:ok, result} ->
          result

        {:error, reason} ->
          Log.error("Error during '#{__MODULE__}' module initialization", reason)
          []
      end

    state = FormatState.new_state(items)
    {:ok, state}
  end

  @impl true
  def count, do: GenServer.call(__MODULE__, :count)
  @impl true
  def count_filter(filter), do: GenServer.call(__MODULE__, {:count_filter, filter})
  @impl true
  def find(limit \\ nil, offset \\ nil, filter \\ nil),
    do: GenServer.call(__MODULE__, {:find, limit, offset, filter})

  @impl true
  def insert(format), do: GenServer.call(__MODULE__, {:insert, format})
  @impl true
  def delete(format \\ nil), do: GenServer.call(__MODULE__, {:delete, format})

  @impl true
  def handle_call(:count, _from, state) do
    count =
      state
      |> Map.get(:items, [])
      |> Enum.count()

    {:reply, {:ok, count}, state}
  end

  def handle_call({:count_filter, nil}, _from, state) do
    {:reply, {:ok, nil}, state}
  end

  def handle_call({:count_filter, filter}, _from, state) do
    count =
      state
      |> filter_items(filter)
      |> Enum.count()

    {:reply, {:ok, count}, state}
  end

  def handle_call({:find, nil, nil, nil}, _from, state) do
    items = Map.get(state, :items, [])
    {:reply, {:ok, items}, state}
  end

  def handle_call({:find, limit, offset, nil}, _from, state) do
    items =
      state
      |> Map.get(:items, [])
      |> Enum.slice(offset, limit)

    {:reply, {:ok, items}, state}
  end

  def handle_call({:find, limit, offset, filter}, _from, state) do
    items =
      state
      |> filter_items(filter)
      |> Enum.slice(offset, limit)

    {:reply, {:ok, items}, state}
  end

  def handle_call({:insert, format}, _from, state) do
    items =
      state
      |> Map.get(:items, [])
      |> Enum.concat([format])

    new_state = Map.put(state, :items, items)

    {:reply, {:ok, items}, new_state}
  end

  def handle_call({:delete, nil}, _from, state) do
    items = Map.get(state, :items, [])
    new_state = Map.put(state, :items, [])

    {:reply, {:ok, items}, new_state}
  end

  def handle_call({:delete, format}, _from, state) do
    {items, new_items} =
      state
      |> Map.get(:items, [])
      |> Enum.split_with(fn v -> v != format end)

    new_state = Map.put(state, :items, new_items)

    {:reply, {:ok, items}, new_state}
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

  def parse_json(json) when is_list(json) do
    result =
      json
      |> Enum.map(fn f -> Map.get(f, "code", "") end)
      |> Enum.filter(fn f -> f != "" end)

    {:ok, result}
  end

  def parse_json(_json) do
    {:error, "The input is not a valid list"}
  end
end
