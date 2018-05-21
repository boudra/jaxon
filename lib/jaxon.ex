defmodule Jaxon do
  @spec decode(String.t()) :: {:ok, Jaxon.Decoder.json_term()} | {:error, String.t()}
  def decode(binary) do
    binary
    |> Jaxon.Parser.parse()
    |> Jaxon.Decoder.events_to_term()
    |> case do
      {:ok, term, _} ->
        {:ok, term}
    end
  end

  @spec decode!(String.t()) :: Jaxon.Decoder.json_term()
  def(decode!(binary)) do
    case decode(binary) do
      {:ok, term} -> term
    end
  end
end
