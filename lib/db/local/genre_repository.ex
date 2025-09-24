defmodule ExStorage.DB.Local.GenreRepository do
  @behaviour ExStorage.DB.RepositoryGenre

  use GenServer

  alias ExStorage.DB.Local.EnumRepository
  alias ExStorage.DB.Local.GenreRepository

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def init(_) do
    EnumRepository.init(%{
      name: __MODULE__,
      file: "./db/genre.json",
      parser: &GenreRepository.parse_json/1
    })
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
    EnumRepository.count(state)
  end

  def handle_call({:count_filter, filter}, _from, state) do
    EnumRepository.count_filter(state, filter)
  end

  def handle_call({:find, limit, offset, filter}, _from, state) do
    EnumRepository.find(state, limit, offset, filter)
  end

  def handle_call({:insert, _format}, _from, state) do
    Log.warn("Local repositories are immutable, the insert request has been ignored.")
    items = Map.get(state, :items, [])
    {:reply, {:ok, items}, state}
  end

  def handle_call({:delete, _format}, _from, state) do
    Log.warn("Local repositories are immutable, the delete request has been ignored.")
    items = Map.get(state, :items, [])
    {:reply, {:ok, items}, state}
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
