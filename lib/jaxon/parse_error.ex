defmodule Jaxon.ParseError do
  @type t :: %__MODULE__{message: String.t()}

  defexception [:message]

  def message(%{message: msg}) do
    msg
  end
end
