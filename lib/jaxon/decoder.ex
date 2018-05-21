defmodule Jaxon.Decoder do
  @moduledoc ~S"""
  ## Example

  Call `decode/1` get a list of decoded events:

  *Note that keys are treated as the same as strings*

  ```
  iex> Jaxon.Decoder.decode("{\"jaxon\":\"rocks\",\"array\":[1,2]}")
  [
   :start_object,
   {:string, "jaxon"},
   {:string, "rocks"},
   {:string, "array"},
   :start_array,
   {:integer, 1},
   {:integer, 2},
   :end_array,
   :end_object,
   :end
  ]
  ```
  """

  @type event ::
          :start_object
          | :end_object
          | :start_array
          | :end_array
          | {:string, binary}
          | {:integer, integer}
          | {:decimal, float}
          | {:boolean, boolean}
          | nil
          | {:incomplete, binary}
          | {:yield, [event], binary}
          | {:error, binary}
          | :end

  @on_load :load_nifs

  def load_nifs do
    nif_filename =
      :jaxon
      |> Application.app_dir("priv/decoder")
      |> to_charlist

    :erlang.load_nif(nif_filename, [
      :start_object,
      :end_object,
      :start_array,
      :end_array,
      :key,
      :string,
      :decimal,
      :integer,
      :boolean,
      nil,
      true,
      false,
      :error,
      :yield,
      :ok,
      :incomplete,
      :end
    ])
  end

  @spec decode_nif(binary) :: [event]
  defp decode_nif(_) do
    raise "NIF not compiled"
  end

  @spec decode(binary) :: [event]
  def decode(binary) do
    case decode_nif(binary) do
      {:yield, events, tail} ->
        # IO.puts("suspended")
        events ++ decode(tail)

      events ->
        events
    end
  end

  def events_to_term(events) do
    events_to_value(events)
  end

  defp events_to_value([:start_object | events]) do
    events_to_object(events, %{})
  end

  defp events_to_value([:start_array | events]) do
    events_to_array(events, [])
  end

  defp events_to_value([{event, value} | events])
       when event in [:string, :decimal, :integer, :boolean] do
    {:ok, value, events}
  end

  defp events_to_value([{:incomplete, {:decimal, value}, _}]) do
    {:ok, value, []}
  end

  defp events_to_value([{:incomplete, {:integer, value}, _}]) do
    {:ok, value, []}
  end

  defp events_to_value([{:incomplete, _} | _]) do
    {:error, "incomplete json"}
  end

  defp events_to_value([nil | events]) do
    {:ok, nil, events}
  end

  defp events_to_array([:end_array | events], array) do
    {:ok, array, events}
  end

  defp events_to_array(events, array) do
    case events_to_value(events) do
      {:ok, value, rest} ->
        events_to_array(rest, array ++ [value])
    end
  end

  defp events_to_object([{:string, key} | events], object) do
    case events_to_value(events) do
      {:ok, value, rest} ->
        events_to_object(rest, Map.put(object, key, value))
    end
  end

  defp events_to_object([:end_object | events], object) do
    {:ok, object, events}
  end
end
