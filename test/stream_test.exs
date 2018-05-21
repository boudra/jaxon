defmodule JaxonEventStreamTest do
  use ExUnit.Case
  doctest Jaxon.Stream
  alias Jaxon.Stream

  @json_stream [
    """
    {
      "numbers": [1,2],
      "person": {
        "name": "Keanu Reeves",
        "movies": [
          { "name": "Speed" },
          { "name": "The Matrix" }
        ]
      }
    }
    """
  ]

  def query(stream, query) do
    stream
    |> Stream.query(query)
    |> Enum.to_list()
  end

  test "queries" do
    assert [1] == query(@json_stream, "$.numbers[0]")
    assert [2] == query(@json_stream, "$.numbers[1]")
    assert [[1, 2]] == query(@json_stream, "$.numbers")
    assert [1, 2] == query(@json_stream, "$.numbers[*]")
    assert ["Keanu Reeves"] == query(@json_stream, "$.person.name")
    assert [%{"name" => "The Matrix"}] == query(@json_stream, "$.person.movies[1]")
    assert ["Speed"] == query(@json_stream, "$.person.movies[0].name")
    assert ["Speed", "The Matrix"] == query(@json_stream, "$.person.movies[*].name")
  end
end
