defmodule Jaxon.Decoders.Query do
  alias Jaxon.ParseError

  @query_object 0
  @query_array 1
  @key 2
  @reduce 3
  @object 4
  @query_key 5
  @array 6
  @query 7
  @skip 8
  @skip_value 9

  def query(_event_stream, []) do
    raise(ArgumentError, "Empty query given")
  end

  def query(event_stream, query) do
    event_stream
    |> Stream.transform({[], [], [:root], {[], query}}, fn events, {tail, stack, path, query} ->
      (tail ++ events)
      |> continue(stack, path, [], query)
      |> case do
        {:yield, tail, stack, path, acc, query} ->
          {:lists.reverse(acc), {tail, stack, path, query}}

        {:error, error} ->
          raise error
      end
    end)
  end

  defp continue([], stack, path, acc, query) do
    {:yield, [], stack, path, acc, query}
  end

  defp continue(e, stack, path, acc, query) do
    case stack do
      stack = [@query_object | _] ->
        query_object(e, stack, path, acc, query)

      stack = [@query_array | _] ->
        query_array(e, stack, path, acc, query)

      [@key | stack] ->
        key(e, stack, path, acc, query)

      [@reduce | stack] ->
        reduce_value(e, stack, path, acc, query)

      [@object | stack] ->
        object(e, stack, path, acc, query)

      [@query_key | stack] ->
        query_key(e, stack, path, acc, query)

      [@array | stack] ->
        array(e, stack, path, acc, query)

      [@query | stack] ->
        query_value(e, stack, path, acc, query)

      stack = [@skip | _] ->
        skip(e, stack, path, acc, query)

      [@skip_value | stack] ->
        skip_value(e, stack, path, acc, query)

      [] ->
        value(e, stack, path, acc, query)
    end
  end

  defp is_match?([q | rest], key) do
    if is_match?(q, key) do
      true
    else
      is_match?(rest, key)
    end
  end

  defp is_match?([], _), do: false
  defp is_match?(key, key), do: true
  defp is_match?(:all, _), do: true
  defp is_match?({min, max}, key) when key >= min and key < max, do: true
  defp is_match?(_, _), do: false

  defp value(e, stack, path = [key | _], acc, query = {prev, [q | next]}) do
    case {is_match?(q, key), next} do
      {true, []} ->
        reduce_value(e, stack, path, acc, query)

      {true, next} ->
        query_value(e, stack, path, acc, {[q | prev], next})

      {false, _} ->
        skip_value(e, stack, path, acc, query)
    end
  end

  # ----- QUERY VALUE

  defp query_value(e, stack, path, acc, query) do
    case e do
      [] ->
        {:yield, [], [@query | stack], path, acc, query}

      [:start_object | e] ->
        query_object(e, [@query_object | stack], [nil | path], acc, query)

      [:start_array | e] ->
        query_array(e, [@query_array | stack], [nil | path], acc, query)

      [e | _] ->
        {:error, ParseError.unexpected_event(e, [:value])}
    end
  end

  defp query_array([:comma | _], _stack, [nil | _path], _acc, _query) do
    {:error, ParseError.unexpected_event(:comma, [:value, :end_array])}
  end

  defp query_array([:comma | e], stack, [key | path], acc, query) do
    value(e, stack, [key + 1 | path], acc, query)
  end

  defp query_array(
         [:end_array | e],
         [@query_array | stack],
         [_key | path],
         acc,
         {[q | prev], next}
       ) do
    continue(e, stack, path, acc, {prev, [q | next]})
  end

  defp query_array([], stack, path, acc, query) do
    {:yield, [], stack, path, acc, query}
  end

  defp query_array(e, stack, [nil | path], acc, query) do
    value(e, stack, [0 | path], acc, query)
  end

  defp query_object([:comma | _], _stack, [nil | _path], _acc, _query) do
    {:error, ParseError.unexpected_event(:comma, [:key, :end_object])}
  end

  defp query_object([:comma | e], stack, path, acc, query) do
    query_key(e, stack, path, acc, query)
  end

  defp query_object(
         [:end_object | e],
         [@query_object | stack],
         [_key | path],
         acc,
         {[q | prev], next}
       ) do
    continue(e, stack, path, acc, {prev, [q | next]})
  end

  defp query_object([], stack, path, acc, query) do
    {:yield, [], stack, path, acc, query}
  end

  defp query_object(e, stack, path = [nil | _], acc, query) do
    query_key(e, stack, path, acc, query)
  end

  defp query_object([e | _], _stack, [nil | _path], _acc, _query) do
    {:error, ParseError.unexpected_event(e, [:key, :end_object])}
  end

  defp query_object([e | _], _stack, _path, _acc, _query) do
    {:error, ParseError.unexpected_event(e, [:comma, :end_object])}
  end

  defp query_key([{:string, key}, :colon | e], stack, [_key | path], acc, query) do
    value(e, stack, [key | path], acc, query)
  end

  defp query_key(e = [{:string, _key}], stack, path, acc, query) do
    {:yield, e, [@query_key | stack], path, acc, query}
  end

  defp query_key(e = [], stack, path, acc, query) do
    {:yield, e, [@query_key | stack], path, acc, query}
  end

  defp query_key([e | _], _stack, _path, _acc, _query) do
    {:error, ParseError.unexpected_event(e, [:key])}
  end

  # ---- REDUCE VALUE

  defp reduce_value(e, stack, path, acc, query) do
    case e do
      [] ->
        {:yield, [], [@reduce | stack], path, acc, query}

      [:start_object | e] ->
        object(e, [[] | stack], [nil | path], acc, query)

      [:start_array | e] ->
        array(e, [[] | stack], [nil | path], acc, query)

      [{type, value} | e] when type in ~w(string decimal integer boolean)a ->
        add_value(e, stack, path, acc, query, value)

      [nil | e] ->
        add_value(e, stack, path, acc, query, nil)

      [e | _] ->
        {:error, ParseError.unexpected_event(e, [:value])}
    end
  end

  defp add_value(e, [object | stack], path = [key | _], acc, query, value)
       when is_binary(key) and is_list(object) do
    object(e, [[{key, value} | object] | stack], path, acc, query)
  end

  defp add_value(e, [object | stack], path = [key | _], acc, query, value)
       when is_integer(key) and is_list(object) do
    array(e, [[value | object] | stack], path, acc, query)
  end

  defp add_value(e, stack, path, acc, query, value) do
    continue(e, stack, path, [value | acc], query)
  end

  defp array([:comma | _], _stack, [nil | _path], _acc, _query) do
    {:error, ParseError.unexpected_event(:comma, [:value, :end_array])}
  end

  defp array([:comma | e], stack, [key | path], acc, query) do
    reduce_value(e, stack, [key + 1 | path], acc, query)
  end

  defp array([:end_array | e], [array | stack], [_key | path], acc, query) when is_list(array) do
    add_value(e, stack, path, acc, query, :lists.reverse(array))
  end

  defp array([], stack, path, acc, query) do
    {:yield, [], [@array | stack], path, acc, query}
  end

  defp array(e, stack, [nil | path], acc, query) do
    reduce_value(e, stack, [0 | path], acc, query)
  end

  defp object([:comma | _], _stack, [nil | _path], _acc, _query) do
    {:error, ParseError.unexpected_event(:comma, [:key, :end_object])}
  end

  defp object([:comma | e], stack, path, acc, query) do
    key(e, stack, path, acc, query)
  end

  defp object([:end_object | e], [object | stack], [_key | path], acc, query)
       when is_list(object) do
    add_value(e, stack, path, acc, query, :maps.from_list(object))
  end

  defp object([], stack, path, acc, query) do
    {:yield, [], [@object | stack], path, acc, query}
  end

  defp object(e, stack, path = [nil | _], acc, query) do
    key(e, stack, path, acc, query)
  end

  defp object([e | _], _stack, [nil | _path], _acc, _query) do
    {:error, ParseError.unexpected_event(e, [:key, :end_object])}
  end

  defp object([e | _], _stack, _path, _acc, _query) do
    {:error, ParseError.unexpected_event(e, [:comma, :end_object])}
  end

  defp key([{:string, key}, :colon | e], stack, [_key | path], acc, query) do
    reduce_value(e, stack, [key | path], acc, query)
  end

  defp key(e = [{:string, _key}], stack, path, acc, query) do
    {:yield, e, [@key | stack], path, acc, query}
  end

  defp key(e = [], stack, path, acc, query) do
    {:yield, e, [@key | stack], path, acc, query}
  end

  defp key([e | _], _stack, _path, _acc, _query) do
    {:error, ParseError.unexpected_event(e, [:key])}
  end

  defp skip_value(e, stack, path, acc, query) do
    case e do
      [] ->
        {:yield, [], [@skip_value | stack], path, acc, query}

      [:start_object | e] ->
        skip(e, [@skip | stack], path, acc, query)

      [:start_array | e] ->
        skip(e, [@skip | stack], path, acc, query)

      [{type, _} | e] when type in ~w(string decimal integer boolean)a ->
        continue(e, stack, path, acc, query)

      [nil | e] ->
        continue(e, stack, path, acc, query)

      [_ | rest] ->
        skip(rest, stack, path, acc, query)
    end
  end

  # ---- SKIP VALUE

  defp skip([:end_object | e], [@skip | stack], path, acc, query) do
    skip(e, stack, path, acc, query)
  end

  defp skip([:end_array | e], [@skip | stack], path, acc, query) do
    skip(e, stack, path, acc, query)
  end

  defp skip([:start_array | e], stack, path, acc, query) do
    skip(e, [@skip | stack], path, acc, query)
  end

  defp skip([:start_object | e], stack, path, acc, query) do
    skip(e, [@skip | stack], path, acc, query)
  end

  defp skip([_ | e], stack = [@skip | _], path, acc, query) do
    skip(e, stack, path, acc, query)
  end

  defp skip([], stack = [@skip | _], path, acc, query) do
    {:yield, [], stack, path, acc, query}
  end

  defp skip(e, stack, path, acc, query) do
    continue(e, stack, path, acc, query)
  end
end
