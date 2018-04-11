defmodule JaxonTest do
  use ExUnit.Case
  doctest Jaxon.Reader

  test "reader" do
    result =
      """
      {"id":0,"name":"john"}
      {"id":2,"pets":["cat","dog"]}
      {}
      """
      |> String.split("\n", trim: true)
      |> Jaxon.Reader.stream_to_rows!([
        "$.id",
        "$.name"
      ])
      |> Enum.to_list()

    assert [[0, "john"], [2, nil], [nil, nil]] == result
  end

  test "array reader" do
    result =
      """
      [ { "name": "john", "age": 36 }, { "name": "mike", "age": 22 } ]
      """
      |> String.split("\n", trim: true)
      |> Jaxon.Reader.stream_to_rows!([
        "$.*.name",
        "$.*.age"
      ])
      |> Enum.to_list()

    assert [["john", 36], ["mike", 22]] == result
  end
end
