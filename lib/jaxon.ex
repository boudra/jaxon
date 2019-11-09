defmodule Jaxon do
  @moduledoc """
  Main Jaxon module.
  """

  @doc """
  Decode a string.

  ```elixir
  iex> Jaxon.decode(~s({"jaxon":"rocks","array":[1,2]}))
  {:ok, %{"array" => [1, 2], "jaxon" => "rocks"}}
  ```
  """
  @spec decode(String.t()) :: {:ok, Jaxon.Decoder.json_term()} | {:error, %Jaxon.ParseError{}}
  def decode(binary) do
    binary
    |> Jaxon.Parser.parse([:end_stream])
    |> Jaxon.Decoder.events_to_term()
  end

  @doc """
  Decode a string, throws if there's an error.

  ```elixir
  iex(1)> Jaxon.decode!(~s({"jaxon":"rocks","array":[1,2]}))
  %{"array" => [1, 2], "jaxon" => "rocks"}
  ```
  """
  @spec decode!(String.t()) :: Jaxon.Decoder.json_term() | no_return()
  def(decode!(binary)) do
    case decode(binary) do
      {:ok, term} -> term
      {:error, err} -> raise err
    end
  end
end
