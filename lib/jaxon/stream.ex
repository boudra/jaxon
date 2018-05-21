defmodule Jaxon.Stream do
  alias Jaxon.{Path, Parser}

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

  def query(bin_stream, path) do
    reduce_query(bin_stream, path, [], fn value, acc ->
      acc ++ [value]
    end)
  end

  def query_multiple(bin_stream, queries) do
    queries = Enum.map(queries, &Path.parse!(&1))

    root =
      queries
      |> List.zip()
      |> Enum.reduce_while([], fn segment, acc ->
        segment
        |> Tuple.to_list()
        |> Enum.min_max()
        |> case do
          {a, a} ->
            {:cont, acc ++ [a]}

          _ ->
            {:halt, acc}
        end
      end)

    queries = Enum.map(queries, &(&1 -- root))

    query(bin_stream, root)
    |> Stream.map(fn record ->
      Enum.map(queries, fn query ->
        access(record, query, [])
      end)
    end)
  end

  def reduce_query(bin_stream, path, initial, reducer) do
    query =
      if is_list(path) do
        path
      else
        Path.parse!(path)
      end

    initial_fun = fn events ->
      events_to_value(events, {[], [:root], initial, query, reducer})
    end

    bin_stream
    |> Stream.transform({initial_fun, ""}, fn chunk, {fun, rest} ->
      chunk = rest <> chunk

      Parser.parse(chunk)
      |> fun.()
      |> case do
        {:incomplete, state, fun, rest} ->
          {state, {fun, rest}}
      end
    end)
  end

  defp events_to_value([:start_object | events], {acc, path, state, query, fun}) do
    events_to_value(events, {[%{} | acc], [:key | path], state, query, fun})
  end

  defp events_to_value([:start_array | events], {acc, path, state, query, fun}) do
    events_to_value(events, {[[] | acc], [0 | path], state, query, fun})
  end

  defp events_to_value([:end_object | events], {[object | acc], [:key | path], state, query, fun}) do
    insert_value(object, events, {acc, path, state, query, fun})
  end

  defp events_to_value([:end_array | events], {[object | acc], [_ | path], state, query, fun}) do
    insert_value(object, events, {acc, path, state, query, fun})
  end

  defp events_to_value([{:string, key} | events], {acc, [:key | path], state, query, fun}) do
    events_to_value(events, {acc, [key | path], state, query, fun})
  end

  defp events_to_value([{event, value} | events], state)
       when event in [:string, :decimal, :integer, :boolean] do
    insert_value(value, events, state)
  end

  defp events_to_value([nil | events], state) do
    insert_value(nil, events, state)
  end

  defp events_to_value([:end], state) do
    {:incomplete, elem(state, 2), &events_to_value(&1, state), ""}
  end

  defp events_to_value([{:incomplete, rest}], state) do
    {:incomplete, elem(state, 2), &events_to_value(&1, state), rest}
  end

  defp events_to_value(:end_stream, {_, _, state, _, _}) do
    state
  end

  defp maybe_call_reducer(value, path, query, state, fun) do
    if query_exact_match?(query, :lists.reverse(path)) do
      fun.(value, state)
    else
      state
    end
  end

  defp insert_value(value, events, {[], path, state, query, fun}) do
    events_to_value(
      events,
      {[value], path, maybe_call_reducer(value, path, query, state, fun), query, fun}
    )
  end

  defp insert_value(value, events, {[parent | acc], full_path = [key | path], state, query, fun})
       when is_map(parent) do
    events_to_value(
      events,
      {[Map.put(parent, key, value) | acc], [:key | path],
       maybe_call_reducer(value, full_path, query, state, fun), query, fun}
    )
  end

  defp insert_value(value, events, {[parent | acc], full_path = [key | path], state, query, fun})
       when is_list(parent) do
    events_to_value(
      events,
      {[parent ++ [value] | acc], [key + 1 | path],
       maybe_call_reducer(value, full_path, query, state, fun), query, fun}
    )
  end

  defp access(record, [], acc) do
    acc ++ [record]
  end

  defp access(record, [:root | path], acc) do
    access(record, path, acc)
  end

  defp access(record, [:all | path], acc) do
    Enum.reduce(record, acc, fn inner, acc ->
      access(inner, path, acc)
    end)
  end

  defp access(record, [key | path], acc)
       when is_list(record) and length(record) > key and key >= 0 do
    access(:lists.nth(key + 1, record), path, acc)
  end

  defp access(record, [key | path], acc) when is_map(record) and is_binary(key) do
    case record do
      %{^key => inner} ->
        access(inner, path, acc)

      _ ->
        acc
    end
  end

  defp access(_, _, acc) do
    acc
  end

  defp query_exact_match?([:all | query], [_ | path]) do
    query_exact_match?(query, path)
  end

  defp query_exact_match?([fragment | query], [fragment | path]) do
    query_exact_match?(query, path)
  end

  defp query_exact_match?([], []) do
    true
  end

  defp query_exact_match?(_, _) do
    false
  end
end
