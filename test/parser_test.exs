defmodule ParseTest do
  use ExUnit.Case
  alias Jaxon.Parser
  doctest Parser

  @tests [
    {~s({ "name": "john", "test": {"number": 5.1}, "tags":[null,true,true,1]}),
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
       {:boolean, true},
       :comma,
       {:integer, 1},
       :end_array,
       :end_object
     ]},
    {~s("string"),
     [
       {:string, "string"}
     ]},
    {~s({"key":"va),
     [
       :start_object,
       {:string, "key"},
       :colon,
       {:incomplete, "\"va"}
     ]},
    {~s("hello" "hello" 1.5 true),
     [
       {:string, "hello"},
       {:string, "hello"},
       {:decimal, 1.5},
       {:boolean, true}
     ]},
    {~s(}}),
     [
       :end_object,
       :end_object
     ]},
    {~s(5e ),
     [
       {:error, "5e "}
     ]},
    {~s(5e),
     [
       {:incomplete, "5e"}
     ]},
    {~s(5..),
     [
       {:error, "5.."}
     ]},
    {~s(5. ),
     [
       {:error, "5. "}
     ]},
    {~s(5.),
     [
       {:incomplete, "5."}
     ]}
  ]

  test "parser tests" do
    Enum.each(@tests, fn {json, events} ->
      assert Parser.parse(json) == events
    end)
  end
end
