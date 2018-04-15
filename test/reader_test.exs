defmodule JaxonReaderTest do
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

    assert [[0, "john"], [2, nil]] == result
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

  test "repeat fields" do
    result =
      """
      [ { "name": "john", "age": 36, "items": [1,2] }, { "name": "mike", "age": 22, "items": [3]} ]
      """
      |> String.split("\n", trim: true)
      |> Jaxon.Reader.stream_to_rows!([
        "$.*.name",
        "$.*.age",
        "$.*.items.*"
      ])
      |> Enum.to_list()

    assert [["john", 36, 1], [nil, nil, 2], ["mike", 22, 3]] == result
  end

  test "errors" do
    stream =
      """
      }
      """
      |> String.split("\n", trim: true)
      |> Jaxon.Reader.stream_to_rows!([
        "$"
      ])

    assert_raise Jaxon.ParseError,
                 "Failed to parse your JSON data, check the syntax near `}`",
                 fn ->
                   Enum.to_list(stream)
                 end
  end
end
