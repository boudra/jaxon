defmodule DecoderTest do
  use ExUnit.Case
  alias Jaxon.Decoder
  doctest Decoder

  @tests [
    {~s({ "name": "john", "test": {"number": 5.1}, "tags":[null,true,true,1]}),
     [
       :start_object,
       {:string, "name"},
       {:string, "john"},
       {:string, "test"},
       :start_object,
       {:string, "number"},
       {:decimal, 5.1},
       :end_object,
       {:string, "tags"},
       :start_array,
       nil,
       {:boolean, true},
       {:boolean, true},
       {:integer, 1},
       :end_array,
       :end_object,
       :end
     ]},
    {~s("string"),
     [
       {:string, "string"},
       :end
     ]},
    {~s({"key":"va),
     [
       :start_object,
       {:string, "key"},
       {:incomplete, "\"va"}
     ]},
    {~s("hello" "hello" 1.5 true),
     [
       {:string, "hello"},
       {:string, "hello"},
       {:decimal, 1.5},
       {:boolean, true},
       :end
     ]},
    {~s(}}),
     [
       :end_object,
       :end_object,
       :end
     ]}
  ]

  test "decoder tests" do
    Enum.each(@tests, fn {json, events} ->
      assert Decoder.decode(json) == events
    end)
  end
end
