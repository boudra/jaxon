defmodule JaxonPathTest do
  use ExUnit.Case
  doctest Jaxon.Path

  test "encode" do
    assert Jaxon.Path.encode([:root, "te.st", 0]) == {:ok, "$.\"te.st\"[0]"}
    assert Jaxon.Path.encode([:root, "test", "0"]) == {:ok, "$.test.0"}
    assert Jaxon.Path.encode([:root, "test", :all]) == {:ok, "$.test[*]"}
  end

  test "parse" do
    assert Jaxon.Path.parse("$.nested.object[2]") == {:ok, [:root, "nested", "object", 2]}
    assert Jaxon.Path.parse("$.\"nested\"") == {:ok, [:root, "nested"]}
    assert Jaxon.Path.parse("$.\"nested\"[0]") == {:ok, [:root, "nested", 0]}
    assert Jaxon.Path.parse("$.\"nested\".0") == {:ok, [:root, "nested", "0"]}
    assert {:error, "Ending quote not found" <> _} = Jaxon.Path.parse("$.\"nested.0")
  end
end
