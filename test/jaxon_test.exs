defmodule JaxonTest do
  use ExUnit.Case
  import Jaxon
  doctest Jaxon

  test "numbers" do
    assert decode!("1494882216.1") == 1_494_882_216.1
    assert decode!("1494882216") == 1_494_882_216
    assert decode!("0") == 0
    assert decode!("23e+4") == 23.0e4
    assert decode!("23.1e+4") == 23.1e4
    assert decode!("23.1e-4") == 23.1e-4
    assert decode!("23.5") == 23.5
    assert decode!("123456789.123456789") == 123_456_789.123456789
    assert decode!("123456789123456789") == 123_456_789123456789
    assert decode!("1") == 1
    assert decode!("-0") == 0
    assert decode!("0") == 0
    assert decode!("0.1") == 0.1
    assert decode!("-0.1") == -0.1
    assert decode!("0e0") == 0
    assert decode!("0E0") == 0
    assert decode!("1e0") == 1
    assert decode!("1E0") == 1
    assert decode!("1.0e0") == 1.0
    assert decode!("1e+0") == 1
    assert decode!("1.0e+0") == 1.0
    assert decode!("0.1e1") == 0.1e1
    assert decode!("0.1e-1") == 0.1e-1
    assert decode!("99.99e99") == 99.99e99
    assert decode!("-99.99e99 ") == -99.99e99
  end

  test "objects" do
    assert decode!(~s({})) == %{}
    assert decode!(~s({"number": 2})) == %{"number" => 2}
    assert decode!(~s({"nested": {}})) == %{"nested" => %{}}
    assert decode!(~s({"nested": {"nested": 2}})) == %{"nested" => %{"nested" => 2}}
  end

  test "arrays" do
    assert decode!(~s([])) == []
    assert decode!(~s([5])) == [5]
    assert decode!(~s([[]])) == [[]]
    assert decode!(~s([[2,5], 3])) == [[2, 5], 3]
  end

  test "strings" do
    assert decode!(~s("hello")) == "hello"
    assert decode!(~s("")) == ""

    assert decode!(~s("\\\n")) == "\n"
    assert decode!(~s("\\\t")) == "\t"
    assert decode!(~s("\\\r")) == "\r"
    assert decode!(~s("\\u0029")) == ")"
    assert decode!(~s("\\u0065")) == "e"
    assert decode!(~s("\\u00E6")) == "æ"
    assert decode!(~s("\\uD83E\\uDD16")) == "🤖"
  end

  test "benchmark files" do
    "bench/data/*.json"
    |> Path.wildcard()
    |> Enum.each(fn filename ->
      :timer.tc(fn ->
        assert {:ok, _} = decode(File.read!(filename))
      end)
    end)
  end

  test "escaped vs unescaped utf8" do
    assert decode!(File.read!("bench/data/utf-8-unescaped.json")) ==
             decode!(File.read!("bench/data/utf-8-escaped.json"))
  end
end
