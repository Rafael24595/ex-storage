defmodule ExStorage.Db.Surealdb.UtilsTest do
  use ExUnit.Case, async: true

  alias ExStorage.Db.Surealdb.Utils

  describe "map_to_filter/1 with binary values" do
    test "simple equality" do
      assert Utils.map_to_filter(%{"title" => "Title_001"}) == ["title = \"Title_001\""]
    end

    test "negated equality" do
      assert Utils.map_to_filter(%{"title" => "!Title_002"}) == ["title != \"Title_002\""]
    end

    test "starts with" do
      assert Utils.map_to_filter(%{"creator" => "Creator_*"}) == ["creator STARTS WITH \"Creator_\""]
    end

    test "ends with" do
      assert Utils.map_to_filter(%{"creator" => "*_001"}) == ["creator ENDS WITH \"_001\""]
    end

    test "contains" do
      assert Utils.map_to_filter(%{"creator" => "*tor_00*"}) == ["creator CONTAINS \"tor_00\""]
    end

    test "greater than" do
      assert Utils.map_to_filter(%{"released" => ">1757256219551"}) == ["released > \"1757256219551\""]
    end

    test "greater or equal" do
      assert Utils.map_to_filter(%{"released" => ">=1757256219551"}) == ["released >= \"1757256219551\""]
    end

    test "less than" do
      assert Utils.map_to_filter(%{"released" => "<released"}) == ["released < \"released\""]
    end
  end

  describe "map_to_filter/1 with number values" do
    test "integer value" do
      assert Utils.map_to_filter(%{"release" => 1_757_256_219_551}) == ["release = 1757256219551"]
    end

    test "float value" do
      assert Utils.map_to_filter(%{"price" => 99.99}) == ["price = 99.99"]
    end
  end

  describe "map_to_filter/1 with list values" do
    test "simple list" do
      assert Utils.map_to_filter(%{"concepts" => ["concept_001", "concept_002"]}) == ["concepts INSIDE [\"concept_001\", \"concept_002\"]"]
    end
  end

  describe "map_to_filter/1 with unsupported values" do
    test "map inside map" do
      assert Utils.map_to_filter(%{"nested" => %{a: 1}}) == []
    end
  end
end
