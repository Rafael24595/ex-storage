defmodule ExStorage.Domain.ConceptV1.Constants do
  @moduledoc false

  def insert_definition do
    [
      %{
        code: "concept",
        title: "Concept",
        type: "string"
      },
      %{
        code: "description",
        title: "Description",
        type: "string"
      }
    ]
  end

  def filter_definition do
    [
      %{
        code: "id",
        title: "Id",
        type: "string"
      },
      %{
        code: "concept",
        title: "Concept",
        type: "string"
      },
      %{
        code: "description",
        title: "Description",
        type: "string"
      }
    ]
  end
end
