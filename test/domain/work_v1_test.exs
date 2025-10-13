defmodule ExStorage.Domain.WorkTest do
  use ExUnit.Case, async: true

  alias ExStorage.Domain.WorkV1.Factory

  describe "fix_filter_map/1" do
    test "Handles release_from and release_to string values" do
      filter =
        Map.new()
        |> Map.put("released_from", "1757256219551")
        |> Map.put("released_to", "1757418721712")

      assert Factory.fix_filter_map(filter) == %{"released" => "1757256219551-1757418721712"}
    end

    test "Handles release_from and release_to number values" do
      filter =
        Map.new()
        |> Map.put("released_from", 1_757_256_219_551)
        |> Map.put("released_to", 1_757_418_721_712)

      assert Factory.fix_filter_map(filter) == %{"released" => "1757256219551-1757418721712"}
    end

    test "Handles release_from and release_to values with different types" do
      filter =
        Map.new()
        |> Map.put("released_from", 1_757_256_219_551)
        |> Map.put("released_to", "1757418721712")

      assert Factory.fix_filter_map(filter) == %{"released" => "1757256219551-1757418721712"}
    end

    test "Handles only release_from as string" do
      filter =
        Map.new()
        |> Map.put("released_from", "1757256219551")

      assert Factory.fix_filter_map(filter) == %{"released" => 1_757_256_219_551}
    end

    test "Handles only release_from as number" do
      filter =
        Map.new()
        |> Map.put("released_from", 1_757_256_219_551)

      assert Factory.fix_filter_map(filter) == %{"released" => 1_757_256_219_551}
    end

    test "Handles only release_to as string" do
      filter =
        Map.new()
        |> Map.put("released_to", "1757418721712")

      assert Factory.fix_filter_map(filter) == %{"released" => 1_757_418_721_712}
    end

    test "Handles only release_to as number" do
      filter =
        Map.new()
        |> Map.put("released_to", 1_757_418_721_712)

      assert Factory.fix_filter_map(filter) == %{"released" => 1_757_418_721_712}
    end
  end
end
