defmodule Jaxon.Decoders.Value do
  alias Jaxon.ParseError

  @array 0
  @object 1

  def decode(events) do
    value(events, [])
  end

  defp parse_error(got, expected) do
    {:error,
     %ParseError{
       unexpected: got,
       expected: expected
     }}
  end

  @compile {:inline, value: 2}
  defp value(e, stack) do
    case e do
      [:start_object | rest] ->
        object(rest, [[] | stack])

      [:start_array | rest] ->
        array(rest, [[] | stack])

      [{:incomplete, {_, value}, _}] ->
        add_value([], stack, value)

      [{:incomplete, _} = other] ->
        parse_error(other, [:value])

      [{type, value} | rest] when type in ~w(string decimal integer boolean)a ->
        add_value(rest, stack, value)

      [value = nil | rest] ->
        add_value(rest, stack, value)

      [other | _] ->
        parse_error(other, [:value])

      [] ->
        parse_error(:end_stream, [:value])
    end
  end

  @compile {:inline, array: 2}
  defp array_next([:comma | rest], stack) do
    value(rest, [@array | stack])
  end

  defp array_next([:end_array | rest], [array | stack]) do
    add_value(rest, stack, :lists.reverse(array))
  end

  defp array_next([other | _rest], _stack) do
    parse_error(other, [:value, :end_array])
  end

  defp array_next([], _stack) do
    parse_error(:end_stream, [:value, :end_array])
  end

  # empty array
  defp array([:end_array | rest], [array | stack]) do
    add_value(rest, stack, array)
  end

  defp array(rest, stack) do
    value(rest, [@array | stack])
  end

  @compile {:inline, add_value: 3}
  defp add_value(e, stack, value) do
    case stack do
      [key, @object, object | stack] ->
        object(e, [[{key, value} | object] | stack])

      [@array, array | stack] ->
        array_next(e, [[value | array] | stack])

      [] ->
        case e do
          [] ->
            {:ok, value}

          [event | _rest] ->
            parse_error(event, [:end_stream])
        end
    end
  end

  @compile {:inline, object: 2}
  defp object([:end_object | rest], [object | stack]) do
    add_value(rest, stack, :maps.from_list(object))
  end

  defp object([:comma | _rest], [[] | _stack]) do
    parse_error(:comma, [:value, :end_object])
  end

  defp object([:comma | rest], stack) do
    key(rest, stack)
  end

  defp object(rest, stack) do
    key(rest, stack)
  end

  @compile {:inline, key: 2}
  defp key(e, stack) do
    case e do
      [{:string, key}, :colon | rest] ->
        value(rest, [key, @object | stack])

      [other | _rest] ->
        parse_error(other, [:key])

      [] ->
        parse_error(:end_stream, [:key])
    end
  end
end
