defmodule Util do
  def chunk_binary(bin, size) when byte_size(bin) >= size do
    {chunk, rest} = :erlang.split_binary(bin, size)
    [chunk | chunk_binary(rest, size)]
  end

  def chunk_binary("", _) do
    []
  end

  def chunk_binary(bin, _) do
    [bin]
  end
end

defmodule JaxonEventStreamTest do
  use ExUnit.Case
  doctest Jaxon.Stream
  alias Jaxon.Stream

  @json_stream ~s(
    {
      "numbers": [1,2],
      "null": null,
      "person": {
        "name": "Keanu Reeves",
        "movies": [
          { "name": "Speed" },
          { "name": "The Matrix" }
        ]
      }
    })

  def query(stream, query) do
    stream
    |> Stream.query(Jaxon.Path.parse!(query))
    |> Enum.to_list()
  end

  test "queries with partial parsing" do
    Enum.each([1, 2, 4, 8, 16, 20, 50], fn chunk_size ->
      stream = Util.chunk_binary(@json_stream, chunk_size)

      assert [1] == query(stream, "$.numbers[0]")
      assert [nil] == query(stream, "$.null")
      assert [2] == query(stream, "$.numbers[1]")
      assert [[1, 2]] == query(stream, "$.numbers")
      assert [1, 2] == query(stream, "$.numbers[*]")
      assert ["Keanu Reeves"] == query(stream, "$.person.name")
      assert [%{"name" => "The Matrix"}] == query(stream, "$.person.movies[1]")
      assert ["Speed"] == query(stream, "$.person.movies[0].name")
      assert ["Speed", "The Matrix"] == query(stream, "$.person.movies[*].name")
    end)
  end

  test "continuous JSON Stream" do
    result =
      [@json_stream]
      |> Elixir.Stream.cycle()
      |> Stream.query([:root, "numbers", :all])
      |> Elixir.Stream.take(30)
      |> Enum.to_list()

    assert Enum.take(Elixir.Stream.cycle([1, 2]), 30) == result
  end

  test "multiple JSON doucuments in a stream chunk" do
    result =
      ["#{@json_stream}\n#{@json_stream}"]
      |> Stream.query([:root, "numbers", :all])
      |> Enum.to_list()

    assert [1, 2, 1, 2] == result
  end

  test "single values" do
    result =
      ["42\n"]
      |> Elixir.Stream.cycle()
      |> Stream.query([:root])
      |> Elixir.Stream.take(30)
      |> Enum.to_list()

    assert Enum.take(Elixir.Stream.cycle([42]), 30) == result

    result =
      [~s({"key":true}\n)]
      |> Elixir.Stream.cycle()
      |> Stream.query([:root])
      |> Elixir.Stream.take(30)
      |> Enum.to_list()

    assert Enum.take(Elixir.Stream.cycle([%{"key" => true}]), 30) == result
  end

  test "it doesn't error when incomplete JSON is streamed" do
    result =
      [~s([{"numbers":[1,2],"key":"hello")]
      |> Stream.query([:root, :all, "key"])
      |> Enum.to_list()

    assert result == ["hello"]
  end
end
