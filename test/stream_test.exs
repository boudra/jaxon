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
    |> Stream.query(query)
    |> Enum.to_list()
  end

  test "queries with partial parsing" do
    Enum.each([1, 2, 4, 8, 16, 20, 50], fn chunk_size ->
      stream = Util.chunk_binary(@json_stream, chunk_size)
      assert [1] == query(stream, "$.numbers[0]")
      assert [1] == query(stream, Jaxon.Path.parse!("$.numbers[0]"))
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
      |> Stream.query("$.numbers[*]")
      |> Elixir.Stream.take(30)
      |> Enum.to_list()

    assert Enum.take(Elixir.Stream.cycle([1, 2]), 30) == result
  end
end
