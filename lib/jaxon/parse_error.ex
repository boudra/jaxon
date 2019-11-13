defmodule Jaxon.ParseError do
  @type t :: %__MODULE__{message: String.t(), unexpected: atom(), expected: [atom()]}

  defexception [:message, :unexpected, :expected]

  defp event_to_pretty_name({:incomplete, {event, _}, _}) do
    event_to_pretty_name(event)
  end

  defp event_to_pretty_name({:incomplete, str}) do
    "incomplete string `#{String.slice(str, 0..15)}`"
  end

  defp event_to_pretty_name({event, _}) do
    event_to_pretty_name(event)
  end

  defp event_to_pretty_name(:integer) do
    "number"
  end

  defp event_to_pretty_name(:value) do
    "string, number, object, array"
  end

  defp event_to_pretty_name(:key) do
    "key"
  end

  defp event_to_pretty_name(:end_object) do
    "closing brace"
  end

  defp event_to_pretty_name(:end_array) do
    "a closing bracket"
  end

  defp event_to_pretty_name(:comma) do
    "comma"
  end

  defp event_to_pretty_name(:colon) do
    "colon"
  end

  defp event_to_pretty_name(:end_stream) do
    "end of stream"
  end

  defp event_to_pretty_name(event) do
    to_string(event)
  end

  @spec message(t()) :: String.t()
  def message(%{message: msg}) when is_binary(msg) do
    msg
  end

  def message(%{unexpected: {:error, context}}) do
    "Syntax error at `#{context}`"
  end

  def message(%{unexpected: unexpected, expected: []}) do
    "Unexpected #{event_to_pretty_name(unexpected)}"
  end

  def message(%{unexpected: unexpected, expected: expected}) do
    expected =
      expected
      |> Enum.map(&event_to_pretty_name/1)
      |> Enum.split(-1)
      |> case do
        {[], [one]} ->
          one

        {h, [t]} ->
          Enum.join(h, ", ") <> " or " <> t
      end

    "Unexpected #{event_to_pretty_name(unexpected)}, expected a #{expected} instead."
  end

  def unexpected_event(got, expected) do
    %__MODULE__{
      unexpected: got,
      expected: expected
    }
  end

  def syntax_error(context) do
    %__MODULE__{
      message: "Syntax error at `#{inspect(context)}`"
    }
  end
end
