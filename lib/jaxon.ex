defmodule Jaxon do
  @moduledoc """
  Main Jaxon module.
  """

  @type json_term() ::
          nil
          | true
          | false
          | list
          | float
          | integer
          | String.t()
          | map
          | [json_term()]

  @doc """
  Decode a string.

  ```elixir
  iex> Jaxon.decode(~s({"jaxon":"rocks","array":[1,2]}))
  {:ok, %{"array" => [1, 2], "jaxon" => "rocks"}}
  ```
  """
  @spec decode(String.t()) :: {:ok, Jaxon.json_term()} | {:error, %Jaxon.ParseError{}}
  def decode(binary) do
    with {:ok, events} <- Jaxon.Parser.parse(binary, allow_incomplete: false) do
      Jaxon.Decoders.Value.decode(events)
    end
  end

  @doc """
  Decode a string, throws if there's an error.

  ```elixir
  iex(1)> Jaxon.decode!(~s({"jaxon":"rocks","array":[1,2]}))
  %{"array" => [1, 2], "jaxon" => "rocks"}
  ```
  """
  @spec decode!(String.t()) :: Jaxon.json_term() | no_return()
  def decode!(binary) do
    case decode(binary) do
      {:ok, term} -> term
      {:error, err} -> raise err
    end
  end
end
