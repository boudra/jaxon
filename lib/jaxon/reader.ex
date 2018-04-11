defmodule Jaxon.Reader do
  alias Jaxon.{Decoder, Path}

  @behaviour Decoder

  @spec stream_to_rows!(Stream.t(), [Path.json_path()]) :: {:ok, Stream.t()}
  def stream_to_rows!(bin_stream, queries) do
    decoder = Jaxon.make_decoder()

    queries =
      queries
      |> Enum.map(&Path.parse!(&1))

    if Enum.any?(queries, &(List.last(&1) == :all)) do
      raise Jaxon.ParseError, message: "A column cannot be a repeat value"
    end

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

    queries =
      queries
      |> Enum.map(fn q ->
        {q, []}
      end)

    initial_state = {decoder, [], {root, queries, nil}, ""}

    bin_stream
    |> Stream.transform(
      fn -> initial_state end,
      fn chunk, {decoder, path, state, rest} ->
        binary = rest <> chunk

        case Decoder.decode(binary, decoder, __MODULE__, {path, state}) do
          {:error, path} ->
            {:halt, {:error, path}}

          {decoder, path, {root, queries, record}, rest} ->
            {queries, results} =
              Enum.map(queries, fn {query, result} ->
                {{query, []}, result}
              end)
              |> Enum.unzip()

            final_results = Enum.map(results, &List.first/1)

            {[final_results], {decoder, path, {root, queries, record}, rest}}
        end
      end,
      fn
        {:error, err} -> raise err
        acc -> acc
      end
    )
  end

  defp match_query([:all | query], [_ | path]) do
    match_query(query, path)
  end

  defp match_query([fragment | query], [fragment | path]) do
    match_query(query, path)
  end

  defp match_query([], rest) do
    {:ok, rest}
  end

  defp match_query(_, _) do
    nil
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

  def close({root, queries, record}, path) do
    path = [:root | Enum.reverse(path)]

    if query_exact_match?(root, path) do
      queries =
        Enum.map(queries, fn {q, acc} ->
          {:ok, query} = match_query(root, q)
          {q, acc ++ access(record, query, [])}
        end)

      {root, queries, nil}
    else
      {root, queries, record}
    end
  end

  def insert({root, queries, record}, path, value) do
    reversed_path = [:root | Enum.reverse(path)]

    case match_query(root, reversed_path) do
      {:ok, rest} ->
        cond do
          !is_list(value) && !is_map(value) ->
            {root, queries, do_insert(record, rest, value)}
            |> close(path)

          true ->
            {root, queries, do_insert(record, rest, value)}
        end

      nil ->
        {root, queries, record}
    end
  end

  defp do_insert(_record, [], value) do
    value
  end

  defp do_insert(record, [key], value) when is_integer(key) and is_list(record) do
    record ++ [value]
  end

  defp do_insert(record, [key | path], value) when is_list(record) do
    List.update_at(record, key, &do_insert(&1, path, value))
  end

  defp do_insert(record, [key | path], value) when is_map(record) do
    Map.update(record, key, value, fn inner ->
      do_insert(inner, path, value)
    end)
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
       when is_list(record) and length(record) > 0 and key >= 0 do
    access(:lists.nth(key + 1, record), path, acc)
  end

  defp access(record, [key | path], acc) when is_map(record) and is_binary(key) do
    case Map.fetch(record, key) do
      :error ->
        acc

      {:ok, inner} ->
        access(inner, path, acc)
    end
  end

  defp access(_, _, acc) do
    acc
  end
end
