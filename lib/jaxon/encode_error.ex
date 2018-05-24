defmodule Jaxon.EncodeError do
  @type t :: %__MODULE__{message: String.t()}

  defexception [:message]

  @spec message(t()) :: String.t()
  def message(%{message: msg}) do
    msg
  end
end
