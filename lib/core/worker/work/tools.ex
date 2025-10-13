defmodule ExStorage.Core.Worker.WorkTools do
  alias ExStorage.Core.Worker.FormatTools
  alias ExStorage.Core.Worker.GenreTools
  alias ExStorage.Domain.WorkV1.Constants

  def insert_definition do
    format = FormatTools.items()
    genres = GenreTools.items()
    concepts = ["condept_001", "condept_002", "condept_003", "condept_004"]
    Constants.insert_definition(format, genres, concepts)
  end

  def filter_definition do
    format = FormatTools.items()
    genres = GenreTools.items()
    concepts = ["condept_001", "condept_002", "condept_003", "condept_004"]
    Constants.filter_definition(format, genres, concepts)
  end
end
