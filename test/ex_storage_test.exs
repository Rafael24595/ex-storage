defmodule ExStorageTest do
  use ExUnit.Case
  doctest ExStorage

  test "greets the world" do
    assert ExStorage.hello() == :world
  end
end
