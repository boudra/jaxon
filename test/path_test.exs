defmodule JaxonPathTest do
  use ExUnit.Case
  doctest Jaxon.Path
  import Jaxon.Path

  test "encode" do
    assert encode!([:root, "te.st", 0]) == "$.\"te.st\"[0]"
    assert encode!([:root, "test", "0"]) == "$.test.0"
    assert encode!([:root, "test", :all]) == "$.test[*]"
    assert encode!([:root, :all]) == "$[*]"
    assert encode!([:root, :all, :all]) == "$[*][*]"
    assert encode!([:root, "$", :all]) == "$.\"$\"[*]"
  end

  test "parse" do
    assert parse!("$.nested.object[2]") == [:root, "nested", "object", 2]
    assert parse!("$.\"nested\"") == [:root, "nested"]
    assert parse!("$.\"nested\"[0]") == [:root, "nested", 0]
    assert parse!("$.\"nested\".0") == [:root, "nested", "0"]
    assert parse!("$.\"$\".0") == [:root, "$", "0"]
    assert {:error, "Ending quote not found" <> _} = parse("$.\"nested.0")
  end
end
