defmodule Jaxon.Decoder do
  alias Jaxon.Path

  @callback insert(any, [String.t() | integer], any) :: any
  @callback close(any, [String.t() | integer]) :: any

  defp handle_event(d, _, {:incomplete, rest}, {path, data}) do
    {d, path, data, rest}
  end

  defp handle_event(d, _, :end, {[], data}) do
    {d, [], data, ""}
  end

  defp handle_event(d, module, :start_array, {path, data}) do
    handle_event(d, module, Jaxon.decode(d), {[-1 | path], module.insert(data, path, [])})
  end

  defp handle_event(d, module, :end_array, {[key | rest], data}) when is_integer(key) do
    handle_event(d, module, Jaxon.decode(d), {rest, module.close(data, rest)})
  end

  defp handle_event(d, module, :start_object, {path = [key | rest], data}) when is_integer(key) do
    handle_event(
      d,
      module,
      Jaxon.decode(d),
      {["", key + 1 | rest], module.insert(data, path, %{})}
    )
  end

  defp handle_event(d, module, :start_object, {path, data}) do
    handle_event(d, module, Jaxon.decode(d), {["" | path], module.insert(data, path, %{})})
  end

  defp handle_event(d, module, :end_object, {[_ | rest], data}) do
    handle_event(d, module, Jaxon.decode(d), {rest, module.close(data, rest)})
  end

  defp handle_event(d, module, {:key, key}, {[_ | path], data}) do
    handle_event(d, module, Jaxon.decode(d), {[key | path], data})
  end

  defp handle_event(d, module, {_, value}, {[key | rest], data}) when is_integer(key) do
    new_path = [key + 1 | rest]
    handle_event(d, module, Jaxon.decode(d), {new_path, module.insert(data, new_path, value)})
  end

  defp handle_event(d, module, {_, value}, {path, data}) do
    handle_event(d, module, Jaxon.decode(d), {path, module.insert(data, path, value)})
  end

  defp handle_event(d, module, value = nil, {[key | rest], data}) when is_integer(key) do
    new_path = [key + 1 | rest]
    handle_event(d, module, Jaxon.decode(d), {new_path, module.insert(data, new_path, value)})
  end

  defp handle_event(d, module, value = nil, {path, data}) do
    handle_event(d, module, Jaxon.decode(d), {path, module.insert(data, path, value)})
  end

  defp handle_event(_, _, :error, {path, _}) do
    case Path.encode(path) do
      {:error, _} ->
        {:error, "Error parsing JSON"}

      path ->
        {:error, "Error parsing value at `#{path}`"}
    end
  end

  def decode(binary, d, module, state) do
    d = Jaxon.update_decoder(d, binary)
    handle_event(d, module, Jaxon.decode(d), state)
  end
end
