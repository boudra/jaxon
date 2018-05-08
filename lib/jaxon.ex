defmodule Jaxon do
  def do_decode(d, {:key, key}, acc, path) do
    do_decode(d, Jaxon.Decoder.decode(d), acc, [key | path])
  end

  def do_decode(d, :start_array, acc, path) do
    do_decode(d, Jaxon.Decoder.decode(d), [[] | acc], path)
  end

  def do_decode(d, :start_object, acc, path) do
    do_decode(d, Jaxon.Decoder.decode(d), [%{} | acc], path)
  end

  def do_decode(_, _, [last], _) do
    {:ok, last}
  end

  def do_decode(_, {:string, value}, [], _) do
    {:ok, value}
  end

  def do_decode(_, {:integer, value}, [], _) do
    {:ok, value}
  end

  def do_decode(_, {:decimal, value}, [], _) do
    {:ok, value}
  end

  def do_decode(_, {:boolean, value}, [], _) do
    {:ok, value}
  end

  def do_decode(d, event, [value, parent | acc], [key | path])
      when event in [:end_array, :end_object] and is_map(parent) do
    do_decode(d, Jaxon.Decoder.decode(d), [Map.put(parent, key, value) | acc], path)
  end

  def do_decode(d, event, [value, parent | acc], path)
      when event in [:end_array, :end_object] and is_list(parent) do
    do_decode(d, Jaxon.Decoder.decode(d), [parent ++ [value] | acc], path)
  end

  def do_decode(d, nil, [%{} = parent | acc], [key | path]) do
    do_decode(d, Jaxon.Decoder.decode(d), [Map.put(parent, key, nil) | acc], path)
  end

  def do_decode(d, value = nil, [parent | acc], path) do
    do_decode(d, Jaxon.Decoder.decode(d), [parent ++ [value] | acc], path)
  end

  def do_decode(d, {event, value}, [parent | acc], [key | path])
      when event in [:string, :integer, :decimal, :boolean] and is_map(parent) do
    do_decode(d, Jaxon.Decoder.decode(d), [Map.put(parent, key, value) | acc], path)
  end

  def do_decode(d, {event, value}, [parent | acc], path)
      when event in [:string, :integer, :decimal, :boolean] and is_list(parent) do
    do_decode(d, Jaxon.Decoder.decode(d), [parent ++ [value] | acc], path)
  end

  def decode(binary) do
    d = Jaxon.Decoder.new() |> Jaxon.Decoder.update(binary)

    do_decode(d, Jaxon.Decoder.decode(d), [], [])
  end

  def decode!(binary) do
    decode(binary)
  end
end
