defmodule Jaxon.Decoders.NifDecoder do
  @on_load :load_nifs
  @behaviour Jaxon.Decoder

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

  @spec decode_nif(String.t()) :: [Jaxon.Event.t()]
  defp decode_nif(_) do
    raise "NIF not compiled"
  end

  @spec decode(String.t()) :: [Jaxon.Event.t()]
  def decode(binary) do
    case decode_nif(binary) do
      {:yield, events, tail} ->
        events ++ decode(tail)

      events ->
        events
    end
  end
end
