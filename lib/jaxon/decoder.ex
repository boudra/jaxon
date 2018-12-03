defmodule Jaxon.Decoder do
  alias Jaxon.{ParseError}
  @moduledoc false
  @type json_term() ::
          nil
          | true
          | false
          | list
          | float
          | integer
          | String.t()
          | map
          | [json_term()]
  @doc """
  Takes a list of events and decodes them into a term.
  """
  @spec events_to_term([Jaxon.Event.t()]) :: json_term()
  def events_to_term(events) do
    events
    |> events_to_value()
    |> do_events_to_term()
  end

  defp do_events_to_term(result) do
    case result do
      {:ok, term, [:end_stream]} ->
        {:ok, term}

      {:ok, term, []} ->
        {:ok, term}

      {:ok, _, [event | _]} ->
        parse_error(event, [:end_stream])

      {:yield, tail, fun} ->
        {:yield, tail,
         fn next ->
           do_events_to_term(fun.(next))
         end}

      {:error, err} ->
        {:error, err}
    end
  end

  def events_to_value([:start_object | events]) do
    events_to_object(events, %{})
  end

  def events_to_value([:start_array | events]) do
    events_to_array(events, [])
  end

  def events_to_value([{event, value} | events])
      when event in [:string, :decimal, :integer, :boolean] do
    {:ok, value, events}
  end

  def events_to_value([nil | events]) do
    {:ok, nil, events}
  end

  def events_to_value([{:incomplete, {:decimal, value}, _}, :end_stream]) do
    {:ok, value, [:end_stream]}
  end

  def events_to_value([{:incomplete, {:integer, value}, _}, :end_stream]) do
    {:ok, value, [:end_stream]}
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

  def events_expect([event | events], event, state) do
    {:ok, events, state}
  end

  def events_expect([{event, _} | _], expected, _) do
    parse_error(event, [expected])
  end

  def events_expect([event | _], expected, _) do
    parse_error(event, [expected])
  end

  defp events_to_array([:end_array | events], array) do
    {:ok, array, events}
  end

  defp events_to_array([:comma | events], array = [_ | _]) do
    events_to_value(events)
    |> add_value_to_array(array)
  end

  defp events_to_array([], array) do
    {:yield, "", &events_to_array(&1, array)}
  end

  defp events_to_array(events, array = []) do
    events_to_value(events)
    |> add_value_to_array(array)
  end

  defp events_to_array([event | _], _) do
    parse_error(event, [:comma, :end_array])
  end

  defp add_value_to_array({:ok, value, rest}, array) do
    events_to_array(rest, array ++ [value])
  end

  defp add_value_to_array(t = {:yield, _, inner}, array) do
    :erlang.setelement(3, t, fn next ->
      add_value_to_array(inner.(next), array)
    end)
  end

  defp add_value_to_array(result, _) do
    result
  end

  defp add_value_to_object({:ok, value, rest}, key, object) do
    events_to_object(rest, Map.put(object, key, value))
  end

  defp add_value_to_object(t = {:yield, _, inner}, key, object) do
    :erlang.setelement(3, t, fn next ->
      add_value_to_object(inner.(next), key, object)
    end)
  end

  defp add_value_to_object(result, _, _) do
    result
  end

  defp events_to_object_key_value([{:incomplete, tail}], object) do
    {:yield, tail, &events_to_object_key_value(&1, object)}
  end

  defp events_to_object_key_value([{:string, key}], object) do
    {:yield, "", &events_to_object_key_value([{:string, key} | &1], object)}
  end

  defp events_to_object_key_value([{:string, key} | rest], object) do
    with {:ok, rest, object} <- events_expect(rest, :colon, object) do
      add_value_to_object(events_to_value(rest), key, object)
    end
  end

  defp events_to_object_key_value([], object) do
    {:yield, "", &events_to_object_key_value(&1, object)}
  end

  defp events_to_object_key_value([event | _], _) do
    parse_error(event, [:key])
  end

  defp events_to_object([:comma | events], object) when map_size(object) > 0 do
    events_to_object_key_value(events, object)
  end

  defp events_to_object([:end_object | events], object) do
    {:ok, object, events}
  end

  defp events_to_object([], object) do
    {:yield, "", &events_to_object(&1, object)}
  end

  defp events_to_object(events, object = %{}) do
    events_to_object_key_value(events, object)
  end

  defp events_to_object([event | _], _) do
    parse_error(event, [:key, :end_object, :comma])
  end
end
