defmodule ExStorage.Core.Worker.WorkTools do
  alias ExStorage.Core.Worker.FormatTools
  alias ExStorage.Domain.Work.Constants

  def insert_definition do
    format_items = FormatTools.items()
    Constants.insert_definition(format_items)
  end

  def filter_definition do
    format_items = FormatTools.items()
    Constants.filter_definition(format_items)
  end
end
