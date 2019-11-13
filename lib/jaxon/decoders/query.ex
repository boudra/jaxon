defmodule Jaxon.Decoders.Query do
  def query(event_stream, query) do
    event_stream
    |> Stream.transform({[], [:root], query}, fn events, {stack, path, query} ->
      events
      |> reduce(stack, [], path, query)
      |> case do
        {:yield, stack, acc, path, query} ->
          {:lists.reverse(acc), {stack, path, query}}
      end
    end)
  end

  defp add_value(e, [:object, object | stack], acc, path = [key | _], queries, value)
       when is_list(object) do
    reduce(e, [:key, :object, [{key, value} | object] | stack], acc, path, queries)
  end

  defp add_value(e, stack = [:object | _], acc, path, queries, value) do
    reduce(e, [:key | stack], [value | acc], path, queries)
  end

  defp add_value(e, [:array, array | stack], acc, [index | path], queries, value)
       when is_list(array) do
    reduce(e, [:array, [value | array] | stack], acc, [index + 1 | path], queries)
  end

  # defp add_value(e, stack = [:array | _], acc, [index | path], queries, value) do
  #   reduce(e, stack, [value | acc], [index + 1 | path], queries)
  # end

  defp add_value(e, stack = [:array | _], acc, [index | path], queries, value) do
    new_acc = [value | acc]

    reduce(e, stack, new_acc, [index + 1 | path], queries)
  end

  defp add_value(e, stack, acc, path, queries, value) do
    new_acc = [value | acc]

    reduce(e, stack, new_acc, path, queries)
  end

  defp ignore_value(e, stack = [:object | _], acc, path, queries) do
    reduce(e, [:key | stack], acc, path, queries)
  end

  defp ignore_value(e, stack = [:array | _], acc, [index | path], queries) do
    reduce(e, stack, acc, [index + 1 | path], queries)
  end

  defp ignore_value(e, stack, acc, path, queries) do
    reduce(e, stack, acc, path, queries)
  end

  defp reduce([:end_array | e], [:skip_array | stack], acc, path, queries) do
    ignore_value(e, stack, acc, path, queries)
  end

  defp reduce([:end_object | e], [:skip_object | stack], acc, path, queries) do
    ignore_value(e, stack, acc, path, queries)
  end

  defp reduce([:start_array | e], stack = [top | _], acc, path, queries)
       when top in [:skip_array, :skip_object] do
    reduce(e, [:skip_array | stack], acc, path, queries)
  end

  defp reduce([:start_object | e], stack = [top | _], acc, path, queries)
       when top in [:skip_array, :skip_object] do
    reduce(e, [:skip_object | stack], acc, path, queries)
  end

  defp reduce([_ | e], stack = [:skip_array | _], acc, path, queries) do
    reduce(e, stack, acc, path, queries)
  end

  defp reduce([_ | e], stack = [:skip_object | _], acc, path, queries) do
    reduce(e, stack, acc, path, queries)
  end

  defp reduce([{:string, key} | e], [:key | stack], acc, [_ | path], queries) do
    reduce(e, stack, acc, [key | path], queries)
  end

  defp reduce([:colon | e], stack, acc, path, queries) do
    reduce(e, stack, acc, path, queries)
  end

  defp reduce([:comma | e], stack, acc, path, queries) do
    reduce(e, stack, acc, path, queries)
  end

  defp reduce([{type, value} | e], stack, acc, path, queries)
       when type in ~w(integer boolean string decimal)a do
    match_queries?(queries, path)
    |> case do
      true ->
        add_value(e, stack, acc, path, queries, value)

      {_, []} ->
        add_value(e, stack, acc, path, queries, value)

      _ ->
        ignore_value(e, stack, acc, path, queries)
    end
  end

  defp reduce([nil | e], stack, acc, path, queries) do
    match_queries?(queries, path)
    |> case do
      true ->
        add_value(e, stack, acc, path, queries, nil)

      {_, []} ->
        add_value(e, stack, acc, path, queries, nil)

      _ ->
        ignore_value(e, stack, acc, path, queries)
    end
  end

  defp reduce([:start_array | e], stack, acc, path, queries) do
    match_queries?(queries, path)
    |> case do
      true ->
        reduce(e, [:array, [] | stack], acc, [0, [] | path], queries)

      {q, next = []} ->
        reduce(e, [:array, [] | stack], acc, [0, [q] | path], next)

      {q, next} ->
        reduce(e, [:array | stack], acc, [0, [q] | path], next)

      false ->
        reduce(e, [:skip_array | stack], acc, path, queries)
    end
  end

  defp reduce([:start_object | e], stack, acc, path, queries) do
    match_queries?(queries, path)
    |> case do
      true ->
        reduce(e, [:key, :object, [] | stack], acc, [nil, [] | path], queries)

      {q, next = []} ->
        reduce(e, [:key, :object, [] | stack], acc, [nil, [q] | path], next)

      {q, next} ->
        reduce(e, [:key, :object | stack], acc, [nil, [q] | path], next)

      false ->
        reduce(e, [:skip_object | stack], acc, path, queries)
    end
  end

  defp reduce([:end_array | e], [:array, array | stack], acc, [_index, q | path], queries)
       when is_list(array) do
    add_value(e, stack, acc, path, q ++ queries, :lists.reverse(array))
  end

  defp reduce([:end_array | e], [:array | stack], acc, [_index, q | path], queries) do
    ignore_value(e, stack, acc, path, q ++ queries)
  end

  defp reduce([:end_object | e], [:key, :object, object | stack], acc, [_key, q | path], queries)
       when is_list(object) do
    add_value(e, stack, acc, path, q ++ queries, :maps.from_list(object))
  end

  defp reduce([:end_object | e], [:key, :object | stack], acc, [_index, q | path], queries) do
    ignore_value(e, stack, acc, path, q ++ queries)
  end

  defp reduce([], stack, acc, path, queries) do
    {:yield, stack, acc, path, queries}
  end

  defp match_queries?([], _) do
    true
  end

  defp match_queries?([q | rest], path) when is_list(q) do
    if do_match_queries?(q, path) do
      {q, rest}
    else
      false
    end
  end

  defp match_queries?([q | rest], [key | _]) do
    if is_match(q, key) do
      {q, rest}
    else
      false
    end
  end

  defp match_queries?([q | rest], path) when is_list(q) do
    if do_match_queries?(q, path) do
      {q, rest}
    else
      false
    end
  end

  defp do_match_queries?([q | rest], path = [key | _]) do
    if is_match(q, key) do
      true
    else
      do_match_queries?(rest, path)
    end
  end

  defp do_match_queries?([], _) do
    false
  end

  defp is_match(key, key), do: true
  defp is_match(:all, _), do: true
  defp is_match({min, max}, key) when key >= min and key < max, do: true
  defp is_match(_, _), do: false
end
