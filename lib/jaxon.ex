defmodule Jaxon do
  @moduledoc """
  Main Jaxon module.
  """

  @decode_chunk_size Application.get_env(:jaxon, :decode_chunk_size, 80 * 1024)

  defp do_decode(binary, offset, size, fun) do
    part = :binary.part(binary, offset, min(size, byte_size(binary) - offset))

    events =
      if offset + size >= byte_size(binary) do
        Jaxon.Parser.parse(part) ++ [:end_stream]
      else
        Jaxon.Parser.parse(part)
      end

    events
    |> fun.()
    |> case do
      {:yield, tail, fun} ->
        do_decode(
          binary,
          offset + size - byte_size(tail),
          max(byte_size(tail) * 2, size),
          fun
        )

      {:ok, result} ->
        {:ok, result}

      {:error, err} ->
        {:error, err}
    end
  end

  @doc """
  Decode a string.

  ```elixir
  iex> Jaxon.decode(~s({"jaxon":"rocks","array":[1,2]}))
  {:ok, %{"array" => [1, 2], "jaxon" => "rocks"}}
  ```
  """
  @spec decode(String.t()) :: {:ok, Jaxon.Decoder.json_term()} | {:error, %Jaxon.ParseError{}}
  def decode(binary) do
    do_decode(binary, 0, @decode_chunk_size, &Jaxon.Decoder.events_to_term/1)
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
