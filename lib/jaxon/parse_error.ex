defmodule Jaxon.ParseError do
  defexception [:message]

  def message(%{message: msg}) do
    msg
  end
end
