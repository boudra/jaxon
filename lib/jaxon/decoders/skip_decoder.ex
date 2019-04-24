defmodule Jaxon.Decoders.SkipDecoder do
  alias Jaxon.{ParseError}

  def events_to_value([:start_object | events]) do
    events_to_object(events)
  end

  def events_to_value([:start_array | events]) do
    events_to_array(events)
  end

  def events_to_value([{event, value} | events])
  when event in [:string, :decimal, :integer, :boolean] do
    {:ok, events}
  end

  def events_to_value([nil | events]) do
    {:ok, events}
  end

  def events_to_value([{:incomplete, {:decimal, value}, _}, :end_stream]) do
    {:ok, [:end_stream]}
  end

  def events_to_value([{:incomplete, {:integer, value}, _}, :end_stream]) do
    {:ok, [:end_stream]}
  end

  def events_to_value([{:incomplete, {:decimal, _}, tail}]) do
    {:yield, tail, &events_to_value(&1)}
  end

  def events_to_value([{:incomplete, {:integer, _}, tail}]) do
    {:yield, tail, &events_to_value(&1)}
  end

  def events_to_value([{:incomplete, tail}]) do
    {:yield, tail, &events_to_value(&1)}
  end

  def events_to_value([]) do
    {:yield, "", &events_to_value(&1)}
  end

  def events_to_value([{:incomplete, _}, :end_stream]) do
    parse_error(:end_stream, [:value])
  end

  def events_to_value([event | _]) do
    parse_error(event, [:value])
  end

  defp parse_error(got, expected) do
    {:error,
      %ParseError{
        unexpected: got,
        expected: expected
      }}
  end

  def events_expect([event | events], event) do
    {:ok, events}
  end

  def events_expect([{event, _} | _], expected) do
    parse_error(event, [expected])
  end

  def events_expect([event | _], expected) do
    parse_error(event, [expected])
  end

  defp events_to_array([:end_array | events]) do
    {:ok, events}
  end

  defp events_to_array([:comma | events]) do
    events
    |> events_to_value()
    |> add_value_to_array()
  end

  defp events_to_array([]) do
    {:yield, "", &events_to_array(&1)}
  end

  defp events_to_array(events) do
    events_to_value(events)
    |> add_value_to_array()
  end

  defp add_value_to_array({:ok, rest}) do
    events_to_array(rest)
  end

  defp add_value_to_array(t = {:yield, _, inner}) do
    :erlang.setelement(3, t, fn next ->
      add_value_to_array(inner.(next))
    end)
  end

  defp add_value_to_array(result) do
    result
  end

  defp add_value_to_object({:ok, rest}) do
    events_to_object(rest)
  end

  defp add_value_to_object(t = {:yield, _, inner}) do
    :erlang.setelement(3, t, fn next ->
      add_value_to_object(inner.(next))
    end)
  end

  defp add_value_to_object(result) do
    result
  end

  defp events_to_object_key_value([{:incomplete, tail}]) do
    {:yield, tail, &events_to_object_key_value(&1)}
  end

  defp events_to_object_key_value([{:string, key}]) do
    {:yield, "", &events_to_object_key_value([{:string, key} | &1])}
  end

  defp events_to_object_key_value([{:string, key} | rest]) do
    with {:ok, rest} <- events_expect(rest, :colon) do
      add_value_to_object(events_to_value(rest))
    end
  end

  defp events_to_object_key_value([]) do
    {:yield, "", &events_to_object_key_value(&1)}
  end

  defp events_to_object_key_value([event | _]) do
    parse_error(event, [:key])
  end

  defp events_to_object([:comma | events]) do
    events_to_object_key_value(events)
  end

  defp events_to_object([:end_object | events]) do
    {:ok, events}
  end

  defp events_to_object([]) do
    {:yield, "", &events_to_object(&1)}
  end

  defp events_to_object(events) do
    events_to_object_key_value(events)
  end

  defp events_to_object([event | _]) do
    parse_error(event, [:key, :end_object, :comma])
  end
end
