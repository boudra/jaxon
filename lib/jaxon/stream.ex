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
  def query(bin_stream, path) do
    query =
      if(
        is_list(path),
        do: path,
        else: Path.parse!(path)
      )
      |> case do
        [:root | path] -> path
        path -> path
      end

    initial_fun = fn events ->
      events_to_value(query, [], events)
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

          {:ok, records, events} ->
            {records, {"", initial_fun}}

          {:error, error} ->
            raise error
        end
    end)
  end

  def add_array_value({:ok, acc, events}, query, _, key) do
    events_to_array(query, acc, key + 1, events)
  end

  def add_array_value({:yield, tail, inner}, query, acc, key) do
    {:yield, tail, &add_array_value(inner.(&1), query, acc, key)}
  end

  def skip_array_value({:ok, _, events}, query, acc, key) do
    events_to_array(query, acc, key + 1, events)
  end

  def skip_array_value({:yield, tail, inner}, query, acc, key) do
    {:yield, tail, &skip_array_value(inner.(&1), query, acc, key)}
  end

  def events_to_array(query, acc, 0, events) do
    events_to_array_value(query, acc, 0, events)
  end

  def events_to_array(query, acc, key, [:comma | events]) do
    events_to_array_value(query, acc, key, events)
  end

  def events_to_array([_ | query], acc, key, [:end_array | events]) do
    {:ok, acc, events}
  end

  def events_to_array(query, acc, key, []) do
    {:yield, "", &events_to_array(query, acc, key, &1)}
  end

  def events_to_array(query, acc, key, [event | _]) do
    {:error, ParseError.unexpected_event(event, [:comma, :end_array])}
  end

  def events_to_array_value(query = [key | rest_query], acc, key, events) do
    add_array_value(events_to_value(rest_query, acc, events), query, acc, key)
  end

  def events_to_array_value(query = [:all | rest_query], acc, key, events) do
    add_array_value(events_to_value(rest_query, acc, events), query, acc, key)
  end

  def events_to_array_value(query, acc, key, events) do
    skip_array_value(Decoder.events_to_value(events), query, acc, key)
  end

  def append_value({:ok, value, rest}, acc) do
    {:ok, acc ++ [value], rest}
  end

  def append_value({:yield, tail, inner}, acc) do
    {:yield, tail, &append_value(inner.(&1), acc)}
  end

  def append_value(other, acc) do
    other
  end

  def events_to_value([], acc, events) do
    append_value(Decoder.events_to_value(events), acc)
  end

  def events_to_value(query, acc, []) do
    {:yield, "", &events_to_value(query, acc, &1)}
  end

  def events_to_value(query, acc, [:start_array | events]) do
    events_to_array(query, acc, 0, events)
  end

  def events_to_value(query, acc, [:start_object | events]) do
    events_to_object(query, acc, events)
  end

  def events_to_object(query, acc, [:end_object | events]) do
    {:ok, acc, events}
  end

  def events_to_object(query, acc, [:comma | events]) do
    events_to_object(query, acc, events)
  end

  def events_to_object(query, acc, []) do
    {:yield, "", &events_to_object(query, acc, &1)}
  end

  def events_to_object(query, acc, [{:incomplete, tail}]) do
    {:yield, tail, &events_to_object(query, acc, &1)}
  end

  def events_to_object(query, acc, [{:string, key}]) do
    {:yield, "", &events_to_object(query, acc, [{:string, key} | &1])}
  end

  def append_object_value({:ok, acc, events}, query, _) do
    events_to_object(query, acc, events)
  end

  def append_object_value({:yield, tail, inner}, query, acc) do
    {:yield, tail, &append_object_value(inner.(&1), query, acc)}
  end

  def append_object_value(other, _, _) do
    other
  end

  def events_to_object([key | query], acc, [{:string, key} | events]) do
    with {:ok, events, acc} <- Decoder.events_expect(events, :colon, acc) do
      append_object_value(events_to_value(query, acc, events), query, acc)
    end
  end

  def skip_object_value({:ok, _, events}, query, acc) do
    events_to_object(query, acc, events)
  end

  def skip_object_value({:yield, tail, inner}, query, acc) do
    {:yield, tail, &skip_object_value(inner.(&1), query, acc)}
  end

  def skip_object_value(other, _, _) do
    other
  end

  def events_to_object(query, acc, [{:string, key} | events]) do
    with {:ok, events, acc} <- Decoder.events_expect(events, :colon, acc) do
      skip_object_value(Decoder.events_to_value(events), query, acc)
    end
  end
end
