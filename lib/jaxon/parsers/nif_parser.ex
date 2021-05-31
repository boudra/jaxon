defmodule Jaxon.Parsers.NifParser do
  @moduledoc false

  @on_load :load_nifs
  @behaviour Jaxon.Parser

  @type parse_return() ::
          {:ok, list(Jaxon.Event.t())}
          | {:incomplete, list(Jaxon.Event.t()), String.t()}
          | {:error, Jaxon.ParseError.t()}

  def load_nifs do
    nif_filename =
      :jaxon
      |> Application.app_dir("priv/decoder")
      |> to_charlist

    :erlang.load_nif(nif_filename, [
      :start_object,
      :end_object,
      :start_array,
      :end_array,
      :comma,
      :colon,
      :string,
      :decimal,
      :integer,
      :boolean,
      nil,
      true,
      false,
      :error,
      :yield,
      :ok,
      :incomplete,
      :end
    ])
  end

  @spec parse_nif(String.t()) ::
          [Jaxon.Event.t()] | {:yield, [Jaxon.Event.t()], String.t()} | no_return()
  defp parse_nif(_) do
    :erlang.nif_error("Jaxon.Parsers.NifParser.parse_nif/1: NIF not compiled")
  end

  @spec do_parse(String.t(), [Jaxon.Event.t()]) :: [Jaxon.Event.t()]
  defp do_parse(binary, acc) do
    case parse_nif(binary) do
      {:yield, events, tail} ->
        do_parse(tail, events ++ acc)

      events ->
        events ++ acc
    end
  end

  @spec parse(String.t(), Keyword.t()) :: parse_return()
  def parse(binary, opts) do
    allow_incomplete = Keyword.get(opts, :allow_incomplete, true)

    case {allow_incomplete, do_parse(binary, [])} do
      {true, [{:incomplete, tail} | events]} ->
        {:incomplete, :lists.reverse(events), tail}

      {true, [{:incomplete, _, tail} | events]} ->
        {:incomplete, :lists.reverse(events), tail}

      {false, [{:incomplete, event, _} | events]} ->
        {:ok, :lists.reverse(events, [event])}

      {false, [err = {:incomplete, _} | _]} ->
        {:error,
         %Jaxon.ParseError{
           unexpected: err,
           expected: [:string]
         }}

      {_, [err = {:error, _} | _]} ->
        {:error, %Jaxon.ParseError{unexpected: err}}

      {_, events} ->
        {:ok, :lists.reverse(events)}
    end
  end
end
