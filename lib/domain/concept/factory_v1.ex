defmodule ExStorage.Domain.ConceptV1.Factory do
  @moduledoc false

  alias ExStorage.Core.DateUtils

  def to_columns(concept) when is_list(concept) do
    [
      {"Timestamp", Enum.map(concept, &DateUtils.from_millis(&1.timestamp))},
      {"Concept", Enum.map(concept, & &1.concept)},
      {"Description", Enum.map(concept, & &1.description)}
    ]
  end

  def to_columns(concept) do
    to_columns([concept])
  end
end
