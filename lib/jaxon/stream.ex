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

  @spec query(Stream.t(), Path.t()) :: [Jaxon.Decoder.json_term()]
  def query(bin_stream, path) do
    reduce_query(bin_stream, path, [], fn value, acc ->
      acc ++ [value]
    end)
  end

  defp reduce_query(bin_stream, path, initial, reducer) do
    query =
      if is_list(path) do
        path
      else
        Path.parse!(path)
      end

    initial_fun = fn events, state ->
      events_to_value(events, {[], [:root], state, query, reducer})
    end

    bin_stream
    |> Stream.concat([:end_stream])
    |> Stream.transform({initial_fun, ""}, fn
      :end_stream, {fun, ""} ->
        {:halt, fun.(:end_stream, initial)}

      chunk, {fun, rest} ->
        chunk = rest <> chunk

        Parser.parse(chunk)
        |> fun.(initial)
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
    yield("", state)
  end

  defp events_to_value([{:incomplete, rest}], state) do
    yield(rest, state)
  end

  defp events_to_value(:end_stream, {_, _, state, _, _}) do
    state
  end

  defp yield(rest, {acc, path, state, query, fun}) do
    {:incomplete, state,
     fn events, state ->
       events_to_value(events, {acc, path, state, query, fun})
     end, rest}
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
