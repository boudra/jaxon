defmodule JaxonPathTest do
  use ExUnit.Case
  doctest Jaxon.Path
  import Jaxon.Path
  alias Jaxon.{ParseError, EncodeError}

  test "encode" do
    assert encode!([:root, "te.st", 0]) == "$.\"te.st\"[0]"
    assert encode!([:root, "test", "0"]) == "$.test.0"
    assert encode!([:root, "test", :all]) == "$.test[*]"
    assert encode!([:root, :all]) == "$[*]"
    assert encode!([:root, :all, :all]) == "$[*][*]"
    assert encode!([:root, "$", :all]) == "$.\"$\"[*]"
    assert encode!([:root, "", :all]) == "$[*]"

    assert_raise(EncodeError, "`:whoops` is not a valid JSON path segment", fn ->
      encode!([:root, :whoops, "test", 0])
    end)
  end

  test "parse" do
    assert parse!("$.nested.object[2]") == [:root, "nested", "object", 2]
    assert parse!("$.\"nested\"") == [:root, "nested"]
    assert parse!("$.nes\\.ted") == [:root, "nes.ted"]
    assert parse!("$.\"nes\\\"ted\"") == [:root, "nes\"ted"]
    assert parse!("$.\"nested\"[0]") == [:root, "nested", 0]
    assert parse!("$.\"nested\".0") == [:root, "nested", "0"]
    assert parse!("$.\"$\".0") == [:root, "$", "0"]

    assert_raise(ParseError, ~r/Ending quote not found.*/, fn ->
      parse!("$.\"nested.0")
    end)

    assert_raise(ParseError, ~r/Expected an integer.*/, fn ->
      parse!("$.nested[hello]")
    end)
  end
end
