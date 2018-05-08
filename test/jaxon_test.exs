defmodule DecoderTest do
  use ExUnit.Case
  alias Jaxon.Decoder
  doctest Decoder

  @tests [
    {"""
     { "name": "john", "test": {"number": 5.1}, "tags":[null,true,true,1]}
     """,
     [
       :start_object,
       {:key, "name"},
       {:string, "john"},
       {:key, "test"},
       :start_object,
       {:key, "number"},
       {:decimal, 5.1},
       :end_object,
       {:key, "tags"},
       :start_array,
       nil,
       {:boolean, true},
       {:boolean, true},
       {:integer, 1},
       :end_array,
       :end_object,
       :end
     ]}
  ]

  defp accumulate(decoder) do
    case Decoder.decode(decoder) do
      event = {type, _} when type in [:incomplete, :error] ->
        [event]

      :end ->
        [:end]

      event ->
        [event | accumulate(decoder)]
    end
  end

  test "basic parsing" do
    Enum.each(@tests, fn {json, events} ->
      d =
        Decoder.new()
        |> Decoder.update(json)

      assert events == accumulate(d)
    end)
  end

  test "string partal parsing" do
    d = Decoder.new()
    Decoder.update(d, "{\"key\":\"va")
    assert [:start_object, {:key, "key"}, {:incomplete, rest}] = accumulate(d)
    Decoder.update(d, rest <> "lue\"}")
    assert [{:string, "value"}, :end_object, :end] = accumulate(d)
  end

  test "constant partal parsing" do
    d = Decoder.new()
    Decoder.update(d, "{\"key\": tr")
    assert [:start_object, {:key, "key"}, {:incomplete, rest}] = accumulate(d)
    Decoder.update(d, rest <> "ue}")
    assert [{:boolean, true}, :end_object, :end] = accumulate(d)
  end

  test "string multiple partal parsing" do
    d = Decoder.new()
    Decoder.update(d, "{\"key\":\"va")
    assert [:start_object, {:key, "key"}, {:incomplete, rest}] = accumulate(d)
    Decoder.update(d, rest <> "lu")
    assert [{:incomplete, rest}] = accumulate(d)
    Decoder.update(d, rest <> "e\"}")
  end

  test "number partal parsing" do
    d = Decoder.new()
    Decoder.update(d, "{\"key\":2342")
    assert [:start_object, {:key, "key"}, {:incomplete, rest}] = accumulate(d)
    Decoder.update(d, rest <> "5 }")
    assert [{:integer, 23425}, :end_object, :end] = accumulate(d)
  end

  test "parsing newline separated json documents in a stream" do
    [{json, events}] = @tests

    times = 100

    expected_events_stream =
      Stream.cycle([events])
      |> Enum.take(times)
      |> List.flatten()

    {_, events} =
      Stream.cycle([json])
      |> Stream.take(times)
      |> Enum.reduce({Decoder.new(), []}, fn line, {d, events} ->
        Decoder.update(d, line)
        events = Enum.concat(events, accumulate(d))
        {d, events}
      end)

    assert events == expected_events_stream
  end

  test "errors" do
    d = Decoder.new()
    Decoder.update(d, "}")
    assert [{:error, "}"}] == accumulate(d)
  end
end
