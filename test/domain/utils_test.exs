defmodule ExStorage.Domain.UtilsTest do
  use ExUnit.Case, async: true

  alias ExStorage.Domain.Utils

  describe "definition_to_map/2" do
    test "Handles a string definition" do
      definition = [%{code: "title", type: "string"}]
      values = %{"title" => %{value: "title_001"}}

      assert Utils.definition_to_map(definition, values) == %{"title" => "title_001"}
    end

    test "Ignores nil code definitions" do
      definition = [%{code: nil, type: "string"}]
      values = %{}

      assert Utils.definition_to_map(definition, values) == %{}
    end

    test "Ignores definitions without values" do
      definition = [%{code: "title", type: "string"}]
      values = %{}

      assert Utils.definition_to_map(definition, values) == %{}
    end

    test "Handles an enum definition with a valid cursor" do
      definition = [%{code: "type", type: "enum", values: ["type_001", "type_002"]}]
      values = %{"type" => %{cursor: 1}}

      assert Utils.definition_to_map(definition, values) == %{"type" => "type_002"}
    end

    test "Ignores an enum definition with an invalid cursor" do
      definition = [%{code: "type", type: "enum", values: ["type_001", "type_002"]}]
      values = %{"type" => %{cursor: 11}}

      assert Utils.definition_to_map(definition, values) == %{}
    end

    test "Handles a tally definition with valid cursors" do
      definition = [%{code: "tags", type: "tally", values: ["tag_001", "tag_002", "tag_003"]}]
      values = %{"tags" => %{:values => [0, 2]}}

      assert Utils.definition_to_map(definition, values) == %{"tags" => ["tag_001", "tag_003"]}
    end

    test "Ignores a tally definition with invalid cursors" do
      definition = [%{code: "tags", type: "tally", values: ["tag_001", "tag_002"]}]
      values = %{"tags" => %{:values => [-1, 99]}}

      assert Utils.definition_to_map(definition, values) == %{"tags" => []}
    end
  end
end
