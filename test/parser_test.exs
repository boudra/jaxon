defmodule ParseTest do
  use ExUnit.Case
  alias Jaxon.{Parser, ParseError}
  doctest Parser

  @tests [
    {~s({ "name": "john", "test": {"number": 5.1}, "tags":[null,true,false,1]}),
     {:ok,
      [
        :start_object,
        {:string, "name"},
        :colon,
        {:string, "john"},
        :comma,
        {:string, "test"},
        :colon,
        :start_object,
        {:string, "number"},
        :colon,
        {:decimal, 5.1},
        :end_object,
        :comma,
        {:string, "tags"},
        :colon,
        :start_array,
        nil,
        :comma,
        {:boolean, true},
        :comma,
        {:boolean, false},
        :comma,
        {:integer, 1},
        :end_array,
        :end_object
      ]}},
    {~s("string"),
     {:ok,
      [
        {:string, "string"}
      ]}},
    {~s({"key":"va),
     {:incomplete,
      [
        :start_object,
        {:string, "key"},
        :colon
      ], "\"va"}},
    {~s("hello" "hello" 1.5 true),
     {:ok,
      [
        {:string, "hello"},
        {:string, "hello"},
        {:decimal, 1.5},
        {:boolean, true}
      ]}},
    {~s(}}),
     {:ok,
      [
        :end_object,
        :end_object
      ]}},
    {~s(5e ), {:error, %ParseError{unexpected: {:error, "5e "}}}},
    {~s(5e), {:incomplete, [], "5e"}},
    {~s(5..), {:error, %ParseError{unexpected: {:error, "5.."}}}},
    {~s(5. ), {:error, %ParseError{unexpected: {:error, "5. "}}}},
    {~s(5.), {:incomplete, [], "5."}},
    {~s("\\u00), {:incomplete, [], ~s("\\u00)}}
  ]

  test "parser tests" do
    Enum.each(@tests, fn {json, events} ->
      result = Parser.parse(json)
      assert result == events
    end)
  end
end
