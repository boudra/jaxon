defmodule Jaxon do
  @moduledoc """
   Simple decoding

  ```elixir
  iex(1)> Jaxon.decode!(~s({"jaxon":"rocks","array":[1,2]}))
  %{"array" => [1, 2], "jaxon" => "rocks"}
  ```

  ```elixir
  iex> Jaxon.decode(~s({"jaxon":"rocks","array":[1,2]}))
  {:ok, %{"array" => [1, 2], "jaxon" => "rocks"}}
  ```
  """

  @spec decode(String.t()) :: {:ok, Jaxon.Decoder.json_term()} | {:error, %Jaxon.ParseError{}}
  def decode(binary) do
    binary
    |> Jaxon.Parser.parse()
    |> Jaxon.Decoder.events_to_term()
    |> case do
      {:ok, term, _} ->
        {:ok, term}
    end
  end

  @spec decode!(String.t()) :: Jaxon.Decoder.json_term() | no_return()
  def(decode!(binary)) do
    case decode(binary) do
      {:ok, term} -> term
    end
  end
end
