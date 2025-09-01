defmodule ExStorage.Core.UtilsTest do
  use ExUnit.Case, async: true

  alias ExStorage.Core.Utils

  describe "decrease_cursor/2" do
    test "decrease non zero cursor" do
      cursor = 1
      options = ["item_001", "item_002", "item_003"]

      assert Utils.decrease_cursor(cursor, options) == 0
    end

    test "decrease zero cursor" do
      cursor = 0
      options = ["item_001", "item_002", "item_003"]

      assert Utils.decrease_cursor(cursor, options) == 2
    end
  end

  describe "increase_cursor/2" do
    test "increase cursor when not at end of list" do
      cursor = 1
      options = ["item_001", "item_002", "item_003"]

      assert Utils.increase_cursor(cursor, options) == 2
    end

    test "increase cursor when at end of list" do
      cursor = 2
      options = ["item_001", "item_002", "item_003"]

      assert Utils.increase_cursor(cursor, options) == 0
    end
  end

  describe "equal_ignore_case?/2" do
    test "compare identical strings" do
      assert Utils.equal_ignore_case?("item_001", "item_001")
    end

    test "compare identical strings with different case" do
      assert Utils.equal_ignore_case?("item_001", "Item_001")
    end

    test "compare different strings" do
      assert !Utils.equal_ignore_case?("item_001", "Item_002")
    end
  end

  describe "match_index/3" do
    setup do
      list = [
        %{id: 1, name: "Item_001"},
        %{id: 2, name: "Item_00A"},
        %{id: 3, name: "Unknown"}
      ]

      %{list: list, extractor: fn item -> item.name end}
    end

    test "finds the index for exact match (case insensitive)", %{list: list, extractor: extractor} do
      assert Utils.match_index(list, "item_001", extractor) == 0
      assert Utils.match_index(list, "Item_00A", extractor) == 1
    end

    test "finds the index for wildcard match", %{list: list, extractor: extractor} do
      assert Utils.match_index(list, "Item_*", extractor) == 0
      assert Utils.match_index(list, "*00A", extractor) == 1
      assert Utils.match_index(list, "U*", extractor) == 2
    end

    test "returns nil when no match found", %{list: list, extractor: extractor} do
      assert Utils.match_index(list, "item_003", extractor) == nil
      assert Utils.match_index(list, "List*", extractor) == nil
    end

    test "returns nil when gets an invalid regex", %{list: list, extractor: extractor} do
      assert Utils.match_index(list, "*[", extractor) == nil
    end
  end

  describe "clean_pointers/2" do
    setup do
      items = ["item_001", "item_002", "item_003"]
      %{items: items}
    end

    test "keeps only valid indices", %{items: items} do
      list = [-1, 0, 1, 2, 3, 10]
      assert Utils.clean_pointers(list, items) == [0, 1, 2]
    end

    test "removes duplicates but keeps first occurrence", %{items: items} do
      list = [2, 2, 1, 1, 0, 0]
      assert Utils.clean_pointers(list, items) == [2, 1, 0]
    end

    test "returns empty list when all indices are invalid", %{items: items} do
      list = [-5, -1, 10, 100]
      assert Utils.clean_pointers(list, items) == []
    end

    test "works with empty list of indices", %{items: items} do
      assert Utils.clean_pointers([], items) == []
    end

    test "works when items is empty" do
      assert Utils.clean_pointers([0, 1, 2], []) == []
    end
  end

  describe "parse_basic_command/1" do
    test "parses command with argument" do
      assert Utils.parse_basic_command("l 10") == {:cmd, "l", "10"}
      assert Utils.parse_basic_command("dt now") == {:cmd, "dt", "now"}
    end

    test "parses command without argument as text" do
      assert Utils.parse_basic_command("c") == {:text, "c"}
    end

    test "preserves spaces in the argument" do
      assert Utils.parse_basic_command("p l:10 o:0") == {:cmd, "p", "l:10 o:0"}
    end

    test "returns empty text for empty input" do
      assert Utils.parse_basic_command("") == {:text, ""}
    end

    test "handles leading and trailing spaces" do
      assert Utils.parse_basic_command("  l 10") == {:cmd, "l", "10"}
      assert Utils.parse_basic_command(" c  ") == {:text, "c"}
    end
  end

  describe "parse_slash_command/1" do
    test "parses slash command with single-letter command" do
      assert Utils.parse_slash_command("\\s *") == {:cmd, "s", "*"}
    end

    test "parses slash command with no arguments" do
      assert Utils.parse_slash_command("\\t") == {:cmd, "t", ""}
      assert Utils.parse_slash_command("\\h   ") == {:cmd, "h", ""}
    end

    test "trims spaces around arguments" do
      assert Utils.parse_slash_command("\\s   *  ") == {:cmd, "s", "*"}
    end

    test "returns empty string if the input does not start with slash" do
      assert Utils.parse_slash_command("l") == {:text, "l"}
      assert Utils.parse_slash_command(" d") == {:text, " d"}
    end

    test "returns empty string for empty input" do
      assert Utils.parse_slash_command("") == {:text, ""}
    end

    test "returns empty string for input with only a slash" do
      assert Utils.parse_slash_command("\\") == {:text, ""}
    end

    test "handles leading and trailing spaces with slash" do
      assert Utils.parse_slash_command("   \\e arg  ") == {:cmd, "e", "arg"}
    end
  end
end
