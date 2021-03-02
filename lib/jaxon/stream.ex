defmodule Jaxon.Stream do
  alias Jaxon.{Path, Parser, Decoders}

  @type event_stream() :: Enumerable.t()
  @type term_stream() :: Enumerable.t()

  @doc """

  Query all values of an array:
  ```
  iex> ~s({ "numbers": [1,2] })
  ...> |> Jaxon.Stream.from_binary()
  ...> |> Jaxon.Stream.query([:root, "numbers", :all])
  ...> |> Enum.to_list()
  [1, 2]
  ```


  Query an object property:
  ```
  iex> ~s({ "person": {"name": "Jose"} })
  ...> |> Jaxon.Stream.from_binary()
  ...> |> Jaxon.Stream.query([:root, "person", "name"])
  ...> |> Enum.to_list()
  ["Jose"]
  ```
  """

  @spec query(event_stream(), Path.t()) :: term_stream()
  defdelegate query(event_stream, query), to: Decoders.Query

  @spec values(event_stream()) :: term_stream()
  defdelegate values(event_stream), to: Decoders.Values

  @doc """
  Transform a binary stream into a stream of events.

  ```elixir
  iex(1)> Jaxon.Stream.from_enumerable([~s({"jaxon"), ~s(:"rocks","array":[1,2]})]) |> Enum.take(1)
  [[:start_object, {:string, "jaxon"}]]
  ```
  """
  @spec from_enumerable(Enumerable.t()) :: event_stream()
  def from_enumerable(bin_stream) do
    Stream.transform(bin_stream, "", fn chunk, tail ->
      chunk = tail <> chunk

      events = Parser.parse(chunk)

      case events do
        {:incomplete, events, tail} ->
          {[events], tail}

        {:error, err} ->
          raise err

        {:ok, events} ->
          {[events], ""}
      end
    end)
  end

  @spec from_binary(String.t()) :: event_stream() | no_return()
  def from_binary(bin) do
    case Parser.parse(bin, allow_incomplete: false) do
      {:ok, events} ->
        [events]

      {:error, err} ->
        raise err
    end
  end
end
