defmodule ExStorage.Domain.WorkV1.Constants do
  @category ["book", "film", "game", "music", "other"]
  @status ["new", "like_new", "very_good", "good", "acceptable", "damaged", "poor", "other"]

  def category do
    @category
  end

  def status do
    @status
  end

  def insert_definition(format, genres, concepts) do
    [
      %{
        code: "title",
        title: "Title",
        type: "string"
      },
      %{
        code: "category",
        title: "Category",
        type: "enum",
        values: @category,
        required: true
      },
      %{
        code: "format",
        title: "Format",
        type: "enum",
        values: format,
        required: true
      },
      %{
        code: "status",
        title: "Status",
        type: "enum",
        values: @status,
        required: true
      },
      %{
        code: "genre",
        title: "Genre",
        type: "tally",
        values: genres,
        required: true
      },
      %{
        code: "publisher",
        title: "Publisher",
        type: "string"
      },
      %{
        code: "direction",
        title: "Direction",
        type: "list"
      },
      %{
        code: "cast",
        title: "Cast",
        type: "list"
      },
      %{
        code: "music",
        title: "Music",
        type: "list"
      },
      %{
        code: "amount",
        title: "Amount",
        type: "number"
      },
      %{
        code: "released",
        title: "Released",
        type: "date"
      },
      %{
        code: "aquired",
        title: "Aquired",
        type: "date"
      },
      %{
        code: "concepts",
        title: "Concepts",
        type: "tally",
        values: concepts
      },
      %{
        code: "tags",
        title: "Tags",
        type: "list"
      }
    ]
  end

  def filter_definition(format, genres, concepts) do
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
        code: "category",
        title: "Category",
        type: "enum",
        values: @category
      },
      %{
        code: "format",
        title: "Format",
        type: "enum",
        values: format
      },
      %{
        code: "status",
        title: "Status",
        type: "enum",
        values: @status
      },
      %{
        code: "genre",
        title: "Genre",
        type: "tally",
        values: genres
      },
      %{
        code: "publisher",
        title: "Publisher",
        type: "list"
      },
      %{
        code: "direction",
        title: "Direction",
        type: "list"
      },
      %{
        code: "cast",
        title: "Cast",
        type: "list"
      },
      %{
        code: "music",
        title: "Music",
        type: "list"
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
        code: "aquired_from",
        title: "Aquired From",
        type: "date"
      },
      %{
        code: "aquired_to",
        title: "Aquired To",
        type: "date"
      },
      %{
        code: "concepts",
        title: "Concepts",
        type: "tally",
        values: concepts
      },
      %{
        code: "tags",
        title: "Tags",
        type: "list"
      }
    ]
  end
end
