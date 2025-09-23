defmodule ExStorage.Domain.UtilsTest do
  use ExUnit.Case, async: true

  alias ExStorage.Domain.DefinitionUtils

  describe "definition_to_map/2" do
    test "handles a string definition" do
      definition = [%{code: "title", type: "string"}]
      values = %{"title" => %{value: "title_001"}}

      assert DefinitionUtils.definition_to_map(definition, values) == %{"title" => "title_001"}
    end

    test "ignores nil code definitions" do
      definition = [%{code: nil, type: "string"}]
      values = %{}

      assert DefinitionUtils.definition_to_map(definition, values) == %{}
    end

    test "ignores definitions without values" do
      definition = [%{code: "title", type: "string"}]
      values = %{}

      assert DefinitionUtils.definition_to_map(definition, values) == %{}
    end

    test "handles an enum definition with a valid cursor" do
      definition = [%{code: "type", type: "enum", values: ["type_001", "type_002"]}]
      values = %{"type" => %{cursor: 1}}

      assert DefinitionUtils.definition_to_map(definition, values) == %{"type" => "type_002"}
    end

    test "ignores an enum definition with an invalid cursor" do
      definition = [%{code: "type", type: "enum", values: ["type_001", "type_002"]}]
      values = %{"type" => %{cursor: 11}}

      assert DefinitionUtils.definition_to_map(definition, values) == %{}
    end

    test "ignores an enum definition with an not defined cursor" do
      definition = [%{code: "type", type: "enum", values: ["type_001", "type_002"]}]
      values = %{"type" => %{}}

      assert DefinitionUtils.definition_to_map(definition, values) == %{}
    end

    test "handles a tally definition with valid cursors" do
      definition = [%{code: "tags", type: "tally", values: ["tag_001", "tag_002", "tag_003"]}]
      values = %{"tags" => %{:value => [0, 2]}}

      assert DefinitionUtils.definition_to_map(definition, values) == %{"tags" => ["tag_001", "tag_003"]}
    end

    test "ignores a tally definition with invalid cursors" do
      definition = [%{code: "tags", type: "tally", values: ["tag_001", "tag_002"]}]
      values = %{"tags" => %{:value => [-1, 99]}}

      assert DefinitionUtils.definition_to_map(definition, values) == %{"tags" => []}
    end
  end
end
