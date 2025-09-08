defmodule ExStorage.DB.SurrealDB.UtilsTest do
  use ExUnit.Case, async: true

  alias ExStorage.DB.SurrealDB.Utils

  describe "map_to_filter/1 with binary values" do
    test "simple equality" do
      assert Utils.map_to_filter(%{"title" => "Title_001"}) == "WHERE title = \"Title_001\""
    end

    test "negated equality" do
      assert Utils.map_to_filter(%{"title" => "!Title_002"}) == "WHERE title != \"Title_002\""
    end

    test "starts with" do
      assert Utils.map_to_filter(%{"creator" => "Creator_*"}) ==
               "WHERE creator STARTS WITH \"Creator_\""
    end

    test "ends with" do
      assert Utils.map_to_filter(%{"creator" => "*_001"}) == "WHERE creator ENDS WITH \"_001\""
    end

    test "contains" do
      assert Utils.map_to_filter(%{"creator" => "*tor_00*"}) ==
               "WHERE creator CONTAINS \"tor_00\""
    end

    test "greater than" do
      assert Utils.map_to_filter(%{"released" => ">1757256219551"}) ==
               "WHERE released > 1757256219551"
    end

    test "greater or equal" do
      assert Utils.map_to_filter(%{"released" => ">=1757256219551"}) ==
               "WHERE released >= 1757256219551"
    end

    test "less than" do
      assert Utils.map_to_filter(%{"released" => "<1757256219551"}) ==
               "WHERE released < 1757256219551"
    end
  end

  describe "map_to_filter/1 with number values" do
    test "integer value" do
      assert Utils.map_to_filter(%{"release" => 1_757_256_219_551}) ==
               "WHERE release = 1757256219551"
    end

    test "float value" do
      assert Utils.map_to_filter(%{"price" => 99.99}) == "WHERE price = 99.99"
    end
  end

  describe "map_to_filter/1 with list values" do
    test "simple list" do
      assert Utils.map_to_filter(%{"concepts" => ["concept_001", "concept_002"]}) ==
               "WHERE concepts INSIDE [\"concept_001\", \"concept_002\"]"
    end
  end

  describe "map_to_filter/1 with empty list" do
    test "simple list" do
      assert Utils.map_to_filter(%{"concepts" => []}) == ""
    end
  end

  describe "map_to_filter/1 with unsupported values" do
    test "map inside map" do
      assert Utils.map_to_filter(%{"nested" => %{a: 1}}) == ""
    end
  end

  describe "map_to_filter/1 with multiple filters" do
    test "handles mixed binary, number and list values" do
      filters =
        Utils.map_to_filter(%{
          "tags" => [],
          "title" => "Title_001",
          "creator" => "Creator_*",
          "released" => ">1757256219551",
          "price" => 99.99
        })

      assert filters ==
               "WHERE creator STARTS WITH \"Creator_\" AND price = 99.99 AND released > 1757256219551 AND title = \"Title_001\""
    end
  end
end
