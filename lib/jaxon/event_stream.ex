defmodule Jaxon.EventStream do
  alias Jaxon.Decoder

  @spec to_term(Enumerable.t()) :: term()
  def to_term(stream) do
    stream
    |> Enum.reduce_while({[], []}, fn
      {:key, key}, {acc, path} ->
        {:cont, {acc, [key | path]}}

      :start_array, {acc, path} ->
        {:cont, {[[] | acc], path}}

      :start_object, {acc, path} ->
        {:cont, {[%{} | acc], path}}

      {event, value}, {[], _}
      when event in [:string, :integer, :decimal, :boolean] ->
        {:halt, {:ok, value}}

      event, {[last], _} when event in [:end_object, :end_array, nil] ->
        {:halt, {:ok, last}}

      event, {[value, parent | acc], [key | path]}
      when event in [:end_array, :end_object] and is_map(parent) ->
        {:cont, {[Map.put(parent, key, value) | acc], path}}

      event, {[value, parent | acc], path}
      when event in [:end_array, :end_object] and is_list(parent) ->
        {:cont, {[parent ++ [value] | acc], path}}

      {event, value}, {[parent | acc], [key | path]}
      when event in [:string, :integer, :decimal, :boolean] and is_map(parent) ->
        {:cont, {[Map.put(parent, key, value) | acc], path}}

      value = nil, {[parent | acc], [key | path]}
      when is_map(parent) ->
        {:cont, {[Map.put(parent, key, value) | acc], path}}

      {event, value}, {[parent | acc], path}
      when event in [:string, :integer, :decimal, :boolean] and is_list(parent) ->
        {:cont, {[parent ++ [value] | acc], path}}

      value = nil, {[parent | acc], path}
      when is_list(parent) ->
        {:cont, {[parent ++ [value] | acc], path}}

      event, _ ->
        {:halt, {:ok, "Failed to parse your JSON, unexpected event #{inspect(event)}"}}
    end)
    |> case do
      {:ok, term} ->
        {:ok, term}

      {:error, msg} ->
        {:error, msg}
    end
  end

  @spec decode(Enumerable.t()) :: Stream.t()
  def decode(bin_stream) do
    bin_stream
    |> Enum.reduce_while({Decoder.new(), [], ""}, fn chunk, {d, acc, rest} ->
      binary = rest <> chunk
      Decoder.update(d, binary)

      case Decoder.consume(d) do
        {:ok, events} ->
          {:halt, {:ok, acc ++ events}}

        {:error, context} ->
          {:halt, {:error, "Failed to parse your JSON data, check the syntax near `#{context}`"}}

        {{:incomplete, rest}, events} ->
          {:cont, {d, acc ++ events, rest}}
      end
    end)
    |> case do
      {_d, _events, rest} ->
        context = String.slice(rest, 0..20)
        {:error, "Failed to parse your JSON data, check the syntax near `#{context}`"}

      {:ok, events} ->
        {:ok, events}

      {:error, error} ->
        {:error, error}
    end
  end

  @spec stream(Enumerable.t()) :: Stream.t()
  def stream(bin_stream) do
    bin_stream
    |> Stream.transform(
      fn -> {Decoder.new(), ""} end,
      fn chunk, {d, rest} ->
        binary = rest <> chunk
        Decoder.update(d, binary)

        case Decoder.consume(d) do
          {:ok, events} ->
            {events, {d, ""}}

          {:end, []} ->
            {:halt, {d, ""}}

          {:end, events} ->
            {events, ""}

          {:error, context} ->
            raise Jaxon.ParseError,
              message: "Failed to parse your JSON data, check the syntax near `#{context}`"

          {{:incomplete, rest}, events} ->
            {events, {d, rest}}
        end
      end,
      fn
        {_d, ""} ->
          :ok

        {_d, rest} ->
          context = String.slice(rest, 0..20)

          raise Jaxon.ParseError,
            message: "Failed to parse your JSON data, check the syntax near `#{context}`"
      end
    )
  end
end
