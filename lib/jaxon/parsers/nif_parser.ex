defmodule Jaxon.Parsers.NifParser do
  @moduledoc false
  @on_load :load_nifs
  @behaviour Jaxon.Parser

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
      :comma,
      :colon,
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

  @spec parse_nif(String.t()) :: [Jaxon.Event.t()]
  defp parse_nif(_) do
    raise "Jaxon.Parsers.NifParser.parse_nif/1: NIF not compiled"
  end

  @spec parse(String.t()) :: [Jaxon.Event.t()]
  def parse(binary) do
    case parse_nif(binary) do
      {:yield, events, tail} ->
        events ++ parse(tail)

      events ->
        events
    end
  end
end
