defmodule Jaxon.Decoder do
  @moduledoc ~S"""
  ## Example

  Create a new decoder and add your JSON data:

  ```
  decoder =
    Jaxon.Decoder.new()
    |> Jaxon.Decoder.update("{\"jaxon\":\"rocks\",\"array\":[1,2]}")
  ```

  Call `decode/1` on the decoder to consume the events one by one:

  ```
  iex> decoder = Jaxon.Decoder.new() |> Jaxon.Decoder.update("{\"jaxon\":\"rocks\",\"array\":[1,2]}")
  iex> Jaxon.Decoder.decode(decoder)
  :start_object
  ```

  Or call `consume/1` to read all the events in a list:

  ```
  iex> decoder = Jaxon.Decoder.new() |> Jaxon.Decoder.update("{\"jaxon\":\"rocks\",\"array\":[1,2]}")
  iex> Jaxon.Decoder.consume(decoder)
  {:ok, [
   :start_object,
   {:key, "jaxon"},
   {:string, "rocks"},
   {:key, "array"},
   :start_array,
   {:integer, 1},
   {:integer, 2},
   :end_array,
   :end_object
  ]}
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

  iex> Jaxon.Decoder.new() |> Jaxon.Decoder.update("{\"jaxon\":\"rocks\"}") |> Jaxon.Decoder.decode()
  :start_object
  """

  @spec decode(decoder) :: event
  def decode(_) do
    raise "NIF not compiled"
  end

  @spec update(decoder, binary) :: decoder
  def update(_, _) do
    raise "NIF not compiled"
  end

  @spec new() :: decoder
  def new() do
    raise "NIF not compiled"
  end

  @spec decode_binary(binary) :: [event]
  def decode_binary(_) do
    raise "NIF not compiled"
  end

  @doc ~S"""
  Helper function that calls `decode/1` until there are no more events.

  ## Example

  iex> Jaxon.Decoder.new() |> Jaxon.Decoder.update("{\"jaxon\":\"rocks\"}") |> Jaxon.Decoder.consume()
  {:ok, [:start_object, {:key, "jaxon"}, {:string, "rocks"}, :end_object]}
  """

  @spec consume(decoder, [event()]) ::
          {{:incomplete, binary}, [event]} | {:ok, [event]} | {:end, [event]}
  def consume(decoder, acc \\ []) do
    case decode(decoder) do
      event = {:incomplete, _} ->
        {event, acc}

      {:error, context} ->
        {:error, context}

      :end ->
        {:ok, acc}

      event ->
        consume(decoder, acc ++ [event])
    end
  end
end
