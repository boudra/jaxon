defmodule Jaxon do
  @moduledoc """
  Documentation for Jaxon.
  """

  @on_load :load_nifs

  def load_nifs do
    file =
      :jaxon
      |> Application.app_dir("priv/decoder")
      |> to_charlist()

    :erlang.load_nif(file, [
      :start_object,
      :end_object,
      :start_array,
      :end_array,
      :key,
      :colon,
      :comma,
      :value,
      :syntax_error,
      :incomplete,
      :end
    ])
  end

  def decode(_) do
    raise "NIF not compiled"
  end

  def update_decoder(_, _) do
    raise "NIF not compiled"
  end

  def make_decoder() do
    raise "NIF not compiled"
  end
end
