defmodule JaxonPathTest do
  use ExUnit.Case
  doctest Jaxon.Path

  test "escapes dots" do
    assert Jaxon.Path.encode([:root, "te.st", 0]) == {:ok, "$.\"te.st\"[0]"}
  end
end
