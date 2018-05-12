defmodule Jaxon do
  def do_decode([{:key, key} | rest], acc, path) do
    do_decode(rest, acc, [key | path])
  end

  def do_decode([:start_array | rest], acc, path) do
    do_decode(rest, [[] | acc], path)
  end

  def do_decode([:start_object | rest], acc, path) do
    do_decode(rest, [%{} | acc], path)
  end

  def do_decode([:end], [acc], _) do
    {:ok, acc}
  end

  def do_decode([{:incomplete, _} | _], _, _) do
    {:error, ""}
  end

  def do_decode([event | rest], [value, parent | acc], [key | path])
      when event in [:end_array, :end_object] and is_map(parent) do
    do_decode(rest, [Map.put(parent, key, value) | acc], path)
  end

  def do_decode([event | rest], [value, parent | acc], path)
      when event in [:end_array, :end_object] and is_list(parent) do
    do_decode(rest, [parent ++ [value] | acc], path)
  end

  def do_decode([:end_object | rest], acc, path) do
    do_decode(rest, acc, path)
  end

  def do_decode([:end_array | rest], acc, path) do
    do_decode(rest, acc, path)
  end

  def do_decode([nil | rest], [%{} = parent | acc], [key | path]) do
    do_decode(rest, [Map.put(parent, key, nil) | acc], path)
  end

  def do_decode([value = nil | rest], [parent | acc], path) do
    do_decode(rest, [parent ++ [value] | acc], path)
  end

  def do_decode([{event, value} | rest], [parent | acc], [key | path])
      when event in [:string, :integer, :decimal, :boolean] and is_map(parent) do
    do_decode(rest, [Map.put(parent, key, value) | acc], path)
  end

  def do_decode([{event, value} | rest], [parent | acc], path)
      when event in [:string, :integer, :decimal, :boolean] and is_list(parent) do
    do_decode(rest, [parent ++ [value] | acc], path)
  end

  def do_decode([{event, value} | rest], acc, path)
      when event in [:string, :integer, :decimal, :boolean] do
    do_decode(rest, [value | acc], path)
  end

  def decode(binary) do
    binary
    |> Jaxon.Decoder.decode_binary()
    |> do_decode([], [])
  end

  def decode!(binary) do
    case decode(binary) do
      {:ok, term} -> term
    end
  end
end
