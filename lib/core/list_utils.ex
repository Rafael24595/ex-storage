defmodule ExStorage.Core.ListUtils do
  def tail([]), do: []
  def tail([_ | tail]), do: tail

  def concat_at([], list2, _index), do: list2
  def concat_at(list1, [], _index), do: list1

  def concat_at(list1, list2, index) do
    {left, right} = Enum.split(list1, index + 1)
    list2 = Enum.concat(list2, right)
    Enum.concat(left, list2)
  end

  def replace_at([], list2, _index), do: list2
  def replace_at(list1, [], _index), do: list1

  def replace_at(list1, list2, index) do
    {left, right} = Enum.split(list1, index)
    list2 = Enum.concat(list2, tail(right))
    Enum.concat(left, list2)
  end

  def chunk_by(list, separator) do
    list
    |> Enum.chunk_by(& &1 == separator)
    |> Enum.reject(fn chunk -> chunk == [separator] end)
  end
end
