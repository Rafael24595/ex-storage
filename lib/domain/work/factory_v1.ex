defmodule ExStorage.Domain.WorkV1.Factory do
  alias ExStorage.Core.DateUtils
  alias ExStorage.Domain.FilterUtils
  alias ExStorage.Domain.WorkV1.Constants

  def to_columns(works) when is_list(works) do
    [
      {"Timestamp", Enum.map(works, &DateUtils.from_millis(&1.timestamp))},
      {"Title", Enum.map(works, & &1.title)},
      {"Category", Enum.map(works, & &1.category)},
      {"Format", Enum.map(works, & &1.format)},
      {"Status", Enum.map(works, & &1.status)},
      {"Genre", Enum.map(works, &Enum.join(&1.genre, ", "))},
      {"Publisher", Enum.map(works, & &1.publisher)},
      {"Direction", Enum.map(works, &Enum.join(&1.direction, ", "))},
      {"Cast", Enum.map(works, &Enum.join(&1.cast, ", "))},
      {"Music", Enum.map(works, &Enum.join(&1.music, ", "))},
      {"Amount", Enum.map(works, &to_string(&1.amount || ""))},
      {"Released", Enum.map(works, &DateUtils.from_millis(&1.released))},
      {"Aquired", Enum.map(works, &DateUtils.from_millis(&1.aquired))},
      {"Concepts", Enum.map(works, &Enum.join(&1.concepts, ", "))},
      {"Tags", Enum.map(works, &Enum.join(&1.tags, ", "))}
    ]
  end

  def to_columns(work) do
    to_columns([work])
  end

  def fix_filter_map(filter) do
    format = []
    genres = []
    concepts = []

    definition = Constants.insert_definition(format, genres, concepts)

    filter
    |> FilterUtils.fix_date_filter("released_from", "released_to", "released")
    |> FilterUtils.fix_date_filter("aquired_from", "aquired_to", "aquired")
    |> FilterUtils.remove_invalid_keys(definition)
  end
end
