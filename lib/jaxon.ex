defmodule Jaxon do
  def decode(binary) do
    binary
    |> Jaxon.Parser.parse()
    |> Jaxon.Decoder.events_to_term()
    |> case do
      {:ok, term, _} ->
        {:ok, term}
    end
  end

  def decode!(binary) do
    case decode(binary) do
      {:ok, term} -> term
    end
  end
end
