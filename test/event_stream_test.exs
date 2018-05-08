defmodule JaxonEventStreamTest do
  use ExUnit.Case
  doctest Jaxon.EventStream
  alias Jaxon.EventStream

  test "reader" do
    # [
    #   "{ \"one\": 1,",
    #   "\"two\": 2",
    #   "\"th",
    #   "ree\": 3",
    #   "}"
    # ]
    # |> EventStream.decode()

    # |> IO.inspect()

    Stream.cycle([File.read!("github.json")])
    |> Stream.take(1_000)
    |> EventStream.stream()
    |> Stream.run()

    # |> IO.inspect()
  end
end
