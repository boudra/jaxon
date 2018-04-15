defmodule Jaxon do
  @moduledoc ~S"""
  ## Example

  Create a new decoder and add your JSON data:

  ```
  decoder =
    Jaxon.make_decoder()
    |> Jaxon.update_decoder("{\"jaxon\":\"rocks\",\"array\":[1,2]}")
  ```

  Call `decode/1` on the decoder to consume the events one by one:

  ```
  iex> decoder = Jaxon.make_decoder() |> Jaxon.update_decoder("{\"jaxon\":\"rocks\",\"array\":[1,2]}")
  iex> Jaxon.decode(decoder)
  :start_object
  ```

  Or call `consume/1` to read all the events in a list:

  ```
  iex> decoder = Jaxon.make_decoder() |> Jaxon.update_decoder("{\"jaxon\":\"rocks\",\"array\":[1,2]}")
  iex> Jaxon.consume(decoder)
  [
   :start_object,
   {:key, "jaxon"},
   {:string, "rocks"},
   {:key, "array"},
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
          | {:key, binary}
          | {:string, binary}
          | {:integer, integer}
          | {:decimal, float}
          | {:boolean, boolean}
          | nil
          | {:incomplete, binary}
          | :end
          | :error

  @type decoder :: reference()

  @on_load :load_nifs

  def load_nifs do
    :erlang.load_nif('./priv/decoder', [
      :start_object,
      :end_object,
      :start_array,
      :end_array,
      :key,
      :colon,
      :comma,
      :string,
      :integer,
      :boolean,
      nil,
      :error,
      :incomplete,
      :syntax_error,
      :end
    ])
  end

  @doc ~S"""
  Get a single event from the decoder, must call `update_decoder/2` with your data beforehand.

  ## Example

  iex> Jaxon.make_decoder() |> Jaxon.update_decoder("{\"jaxon\":\"rocks\"}") |> Jaxon.decode()
  :start_object
  """

  @spec decode(decoder) :: event
  def decode(_) do
    raise "NIF not compiled"
  end

  @spec update_decoder(decoder, binary) :: decoder
  def update_decoder(_, _) do
    raise "NIF not compiled"
  end

  @spec make_decoder() :: decoder
  def make_decoder() do
    raise "NIF not compiled"
  end

  @doc ~S"""
  Helper function that calls `decode/1` until there are no more events.

  ## Example

  iex> Jaxon.make_decoder() |> Jaxon.update_decoder("{\"jaxon\":\"rocks\"}") |> Jaxon.consume()
  [:start_object, {:key, "jaxon"}, {:string, "rocks"}, :end_object, :end]
  """

  @spec consume(decoder) :: [event]
  def consume(decoder) do
    case Jaxon.decode(decoder) do
      event = {:incomplete, _} ->
        [event]

      event when event in [:end, :error, :ok] ->
        [event]

      event ->
        [event | consume(decoder)]
    end
  end
end
