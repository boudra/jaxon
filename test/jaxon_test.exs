defmodule JaxonTest do
  use ExUnit.Case
  doctest Jaxon

  @basic_json """
  { "name": "john", "test": {"Whot": 5}, "tags":[23233]}
  """

  def accumulate(decoder) do
    case Jaxon.decode(decoder) do
      event when event in [:end, :incomplete, :error, :ok] ->
        [IO.inspect(event)]

      event ->
        [IO.inspect(event) | accumulate(decoder)]
    end
  end

  test "basic parsing" do
    x = Jaxon.make_decoder()
    Jaxon.update_decoder(x, @basic_json)

    IO.inspect(accumulate(x))
  end

  test "newline json parsing" do
    x = Jaxon.make_decoder()

    File.stream!("../sqlify/one.json", [], :line)
    |> Stream.take(1)
    |> Enum.map(fn chunk ->
      Jaxon.update_decoder(x, chunk)

      accumulate(x)
    end)
  end
end
