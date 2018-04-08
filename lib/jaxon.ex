defmodule Jaxon do
  @moduledoc """
  Documentation for Jaxon.
  """

  @type event ::
          :start_object
          | :end_object
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
end
