defmodule Jaxon.Decoder do
  @decoder Application.get_env(:jaxon, :decoder, Jaxon.Decoders.NifDecoder)

  @callback decode(String.t()) :: [Jaxon.Event.t()]

  @type json_term() ::
          nil
          | true
          | false
          | list
          | float
          | integer
          | String.t()
          | map

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

  @spec decode(String.t()) :: [Jaxon.Event.t()]
  defdelegate decode(events), to: @decoder

  @spec events_to_term([Jaxon.Event.t()]) :: json_term()
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
