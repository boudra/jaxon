defmodule Jaxon.Stream do
  alias Jaxon.{Path, Parser, ParseError, Decoder}

  @doc """

  Query all values of an array:
  ```
  iex> ~s({ "numbers": [1,2] }) |> List.wrap() |> Jaxon.Stream.query("$.numbers[*]") |> Enum.to_list()
  [1, 2]
  ```


  Query an object property:
  ```
  iex> ~s({ "person": {"name": "Jose"} }) |> List.wrap() |> Jaxon.Stream.query("$.person.name") |> Enum.to_list()
  ["Jose"]
  ```
  """

  @spec query(Stream.t(), Path.t()) :: Stream.t()
  def query(bin_stream, [:root | rest]) do
    query(bin_stream, rest)
  end

  def query(bin_stream, query) do
    initial_fun = fn events ->
      query_value(query, [], events)
    end

    bin_stream
    |> Stream.concat([:end_stream])
    |> Stream.transform({"", initial_fun}, fn
      :end_stream, {"", _} ->
        {:halt, nil}

      chunk, {tail, fun} ->
        chunk = tail <> chunk

        Parser.parse(chunk)
        |> fun.()
        |> case do
          {:yield, tail, fun} ->
            {[], {tail, fun}}

          {:ok, records, _events} ->
            {records, {"", initial_fun}}

          {:error, error} ->
            raise error
        end
    end)
  end

  def query_value([], acc, events) do
    append_value(Decoder.events_to_value(events), acc)
  end

  def query_value(query, acc, []) do
    {:yield, "", &query_value(query, acc, &1)}
  end

  def query_value(query, acc, [:start_array | events]) do
    query_array(query, acc, 0, events)
  end

  def query_value(query, acc, [:start_object | events]) do
    query_object(query, acc, events)
  end

  defp append_value({:ok, value, rest}, acc) do
    {:ok, acc ++ [value], rest}
  end

  defp append_value({:yield, tail, inner}, acc) do
    {:yield, tail, &append_value(inner.(&1), acc)}
  end

  defp append_value(other, _acc) do
    other
  end

  defp add_array_value({:ok, acc, events}, query, _, key) do
    query_array(query, acc, key + 1, events)
  end

  defp add_array_value({:yield, tail, inner}, query, acc, key) do
    {:yield, tail, &add_array_value(inner.(&1), query, acc, key)}
  end

  defp skip_array_value({:ok, _, events}, query, acc, key) do
    query_array(query, acc, key + 1, events)
  end

  defp skip_array_value({:yield, tail, inner}, query, acc, key) do
    {:yield, tail, &skip_array_value(inner.(&1), query, acc, key)}
  end

  defp query_array(query, acc, 0, events) do
    query_array_value(query, acc, 0, events)
  end

  defp query_array(query, acc, key, [:comma | events]) do
    query_array_value(query, acc, key, events)
  end

  defp query_array(_query, acc, _key, [:end_array | events]) do
    {:ok, acc, events}
  end

  defp query_array(query, acc, key, []) do
    {:yield, "", &query_array(query, acc, key, &1)}
  end

  defp query_array(_query, _acc, _key, [event | _]) do
    {:error, ParseError.unexpected_event(event, [:comma, :end_array])}
  end

  defp query_array_value(query = [key | rest_query], acc, key, events) do
    add_array_value(query_value(rest_query, acc, events), query, acc, key)
  end

  defp query_array_value(query = [:all | rest_query], acc, key, events) do
    add_array_value(query_value(rest_query, acc, events), query, acc, key)
  end

  defp query_array_value(query, acc, key, events) do
    skip_array_value(Decoder.events_to_value(events), query, acc, key)
  end

  defp append_object_value({:ok, acc, events}, query, _) do
    query_object(query, acc, events)
  end

  defp append_object_value({:yield, tail, inner}, query, acc) do
    {:yield, tail, &append_object_value(inner.(&1), query, acc)}
  end

  defp append_object_value(other, _, _) do
    other
  end

  defp skip_object_value({:ok, _, events}, query, acc) do
    query_object(query, acc, events)
  end

  defp skip_object_value({:yield, tail, inner}, query, acc) do
    {:yield, tail, &skip_object_value(inner.(&1), query, acc)}
  end

  defp skip_object_value(other, _, _) do
    other
  end

  defp query_object(_query, acc, [:end_object | events]) do
    {:ok, acc, events}
  end

  defp query_object(query, acc, [:comma | events]) do
    query_object(query, acc, events)
  end

  defp query_object(query, acc, []) do
    {:yield, "", &query_object(query, acc, &1)}
  end

  defp query_object(query, acc, [{:incomplete, tail}]) do
    {:yield, tail, &query_object(query, acc, &1)}
  end

  defp query_object(query, acc, [{:string, key}]) do
    {:yield, "", &query_object(query, acc, [{:string, key} | &1])}
  end

  defp query_object([key | query], acc, [{:string, key} | events]) do
    with {:ok, events, acc} <- Decoder.events_expect(events, :colon, acc) do
      append_object_value(query_value(query, acc, events), query, acc)
    end
  end

  defp query_object(query, acc, [{:string, _key} | events]) do
    with {:ok, events, acc} <- Decoder.events_expect(events, :colon, acc) do
      skip_object_value(Decoder.events_to_value(events), query, acc)
    end
  end
end
