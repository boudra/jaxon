defmodule Jaxon.Decoders.ValuesDecoder do
  alias Jaxon.{Parser, ParseError}

  def stream(bin_stream) do
    bin_stream
    |> Stream.concat([:end_stream])
    |> Stream.transform({"", &initial_fun/1}, fn
      :end_stream, {tail, fun} ->
        chunk = tail

        chunk
        |> Parser.parse()
        |> Enum.concat([:end_stream])
        |> do_resume_stream_values(fun, [])

      chunk, {tail, fun} ->
        chunk = tail <> chunk

        chunk
        |> Parser.parse()
        |> do_resume_stream_values(fun, [])
    end)
  end

  defp initial_fun(events) do
    do_stream_value(events, [], [])
  end

  def do_resume_stream_values(events, fun, acc) do
    events
    |> fun.()
    |> case do
      {:ok, values, []} ->
        {acc ++ values, {"", &initial_fun/1}}

      {:ok, values, events} ->
        do_resume_stream_values(events, &initial_fun/1, acc ++ values)

      {:yield, values, tail, fun} ->
        {values, {tail, fun}}

      {:error, error} when is_binary(error) ->
        raise ParseError.syntax_error(error)

      {:error, error} ->
        raise error
    end
  end

  defp do_stream_value([:start_object | events], path, acc) do
    events_to_object(events, path, acc ++ [{path, :start_object}])
  end

  defp do_stream_value([:start_array | events], path, acc) do
    events_to_array(events, 0, path, acc ++ [{path, :start_array}])
  end

  defp do_stream_value([{event, value} | events], path, acc)
       when event in [:string, :decimal, :integer, :boolean] do
    {:ok, acc ++ [{path, value}], events}
  end

  defp do_stream_value([nil | events], path, acc) do
    {:ok, acc ++ [{path, nil}], events}
  end

  defp do_stream_value([{:incomplete, {:decimal, value}, _}, :end_stream], [], acc) do
    {:ok, acc ++ [{[], value}], []}
  end

  defp do_stream_value([{:incomplete, {:integer, value}, _}, :end_stream], [], acc) do
    {:ok, acc ++ [{[], value}], []}
  end

  defp do_stream_value([{:incomplete, {:decimal, _}, tail}], path, acc) do
    {:yield, acc, tail, &do_stream_value(&1, path, [])}
  end

  defp do_stream_value([{:incomplete, {:integer, _}, tail}], path, acc) do
    {:yield, acc, tail, &do_stream_value(&1, path, [])}
  end

  defp do_stream_value([{:incomplete, tail}], path, acc) do
    {:yield, acc, tail, &do_stream_value(&1, path, [])}
  end

  defp do_stream_value([:end_stream], _, acc) do
    {:ok, acc, []}
  end

  defp do_stream_value([], path, acc) do
    {:yield, acc, "", &do_stream_value(&1, path, [])}
  end

  defp do_stream_value([{:incomplete, _}, :end_stream], _, _) do
    {:error, ParseError.unexpected_event(:end_stream, [:value])}
  end

  defp do_stream_value([event | _], _, _) do
    {:error, ParseError.unexpected_event(event, [:value])}
  end

  # Object

  defp add_value_to_object({:ok, acc, rest}, path) do
    events_to_object(rest, path, acc)
  end

  defp add_value_to_object({:yield, acc, tail, inner}, path) do
    {:yield, acc, tail, &add_value_to_object(inner.(&1), path)}
  end

  defp add_value_to_object(result, _) do
    result
  end

  defp events_to_object_key_value([{:incomplete, tail}], path, acc) do
    {:yield, acc, tail, &events_to_object_key_value(&1, path, [])}
  end

  defp events_to_object_key_value([{:string, key}], path, acc) do
    {:yield, acc, "", &events_to_object_key_value([{:string, key} | &1], path, [])}
  end

  defp events_to_object_key_value([{:string, key} | rest], path, acc) do
    new_path = path ++ [key]

    with {:ok, rest} <- events_expect(rest, :colon) do
      add_value_to_object(do_stream_value(rest, new_path, acc), path)
    end
  end

  defp events_to_object_key_value([], path, acc) do
    {:yield, acc, "", &events_to_object_key_value(&1, path, [])}
  end

  defp events_to_object_key_value([event | _], _, _) do
    {:error, ParseError.unexpected_event(event, [:key])}
  end

  defp events_to_object(events = [{:string, _} | _], path, acc) do
    events_to_object_key_value(events, path, acc)
  end

  defp events_to_object(events = [{:incomplete, _} | _], path, acc) do
    events_to_object_key_value(events, path, acc)
  end

  defp events_to_object([:comma | events], path, acc) do
    events_to_object_key_value(events, path, acc)
  end

  defp events_to_object([:end_object | events], path, acc) do
    {:ok, acc ++ [{path, :end}], events}
  end

  defp events_to_object([], path, acc) do
    {:yield, acc, "", &events_to_object(&1, path, [])}
  end

  defp events_to_object([event | _], _, _) do
    {:error, ParseError.unexpected_event(event, [:key, :end_object, :comma])}
  end

  # Array

  defp add_value_to_array({:ok, acc, rest}, index, path) do
    events_to_array(rest, index, path, acc)
  end

  defp add_value_to_array({:yield, acc, tail, inner}, index, path) do
    {:yield, acc, tail, &add_value_to_array(inner.(&1), index, path)}
  end

  defp add_value_to_array(result, _, _) do
    result
  end

  defp events_to_array([:comma | events], index, path, acc) do
    events_to_array(events, index + 1, path, acc)
  end

  defp events_to_array([:end_array | events], _, path, acc) do
    {:ok, acc ++ [{path, :end}], events}
  end

  defp events_to_array([], index, path, acc) do
    {:yield, acc, "", &events_to_array(&1, index, path, [])}
  end

  defp events_to_array(events, index, path, acc) do
    add_value_to_array(do_stream_value(events, path ++ [index], acc), index, path)
  end

  # Helpers

  def events_expect([event | events], event) do
    {:ok, events}
  end

  def events_expect([{event, _} | _], expected) do
    {:error, ParseError.unexpected_event(event, [expected])}
  end

  def events_expect([event | _], expected) do
    {:error, ParseError.unexpected_event(event, [expected])}
  end
end
