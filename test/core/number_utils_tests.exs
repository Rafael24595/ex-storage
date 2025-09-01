defmodule ExStorage.Core.NumberUtilsTest do
  describe "integer_parse/2 unified" do
    test "parses valid integer string" do
      assert NumberUtils.integer_parse("123") == {:ok, 123}
      assert NumberUtils.integer_parse("0") == {:ok, 0}
      assert NumberUtils.integer_parse("-42") == {:ok, -42}
    end

    test "returns :error for invalid string without default" do
      assert NumberUtils.integer_parse("12abc") == :error
      assert NumberUtils.integer_parse("abc") == :error
    end

    test "returns default if string is invalid and default is integer" do
      assert NumberUtils.integer_parse("abc", 10) == 10
      assert NumberUtils.integer_parse("12a", 0) == 0
    end

    test "returns :error if string is invalid and default is not integer" do
      assert NumberUtils.integer_parse("abc", :error) == :error
      assert NumberUtils.integer_parse("12a", "default") == :error
    end

    test "returns parsed integer when valid with default" do
      assert NumberUtils.integer_parse("42", 10) == {:ok, 42}
    end
  end
end
