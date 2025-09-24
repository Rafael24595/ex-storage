defmodule ExStorage.Domain.Work.Constants do

  @category ["book", "film", "game", "music", "other"]

  def category do
    @category
  end

  def insert_definition(format) do
    [
      %{
        code: "title",
        title: "Title",
        type: "string"
      },
      %{
        code: "creator",
        title: "Creator",
        type: "string"
      },
      %{
        code: "released",
        title: "Released",
        type: "date"
      },
      %{
        code: "tags",
        title: "Tags",
        type: "list"
      },
      %{
        code: "type",
        title: "Type",
        type: "enum",
        values: @category,
        required: true
      },
      %{
        code: "concepts",
        title: "Concepts",
        type: "tally",
        values: ["condept_001", "condept_002", "condept_003", "condept_004"]
      },
      %{
        code: "format",
        title: "Format",
        type: "enum",
        values: format,
        required: true
      }
    ]
  end

  def filter_definition(format) do
    [
      %{
        code: "id",
        title: "Id",
        type: "string"
      },
      %{
        code: "title",
        title: "Title",
        type: "string"
      },
      %{
        code: "creator",
        title: "Creator",
        type: "string"
      },
      %{
        code: "released_from",
        title: "Released From",
        type: "date"
      },
      %{
        code: "released_to",
        title: "Released To",
        type: "date"
      },
      %{
        code: "tags",
        title: "Tags",
        type: "list"
      },
      %{
        code: "type",
        title: "Type",
        type: "enum",
        values: @category
      },
      %{
        code: "concepts",
        title: "Concepts",
        type: "tally",
        values: ["condept_001", "condept_002", "condept_003", "condept_004"]
      },
      %{
        code: "format",
        title: "Format",
        type: "enum",
        values: format
      }
    ]
  end
end
