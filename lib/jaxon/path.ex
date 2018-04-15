defmodule Jaxon.Path do
  alias Jaxon.ParseError

  @moduledoc ~S"""
  Utility module for parsing and encoding JSON path expressions.
  """

  @type json_path :: [String.t() | atom | integer]

  @doc ~S"""
  Encoding path expressions:

  ```
  iex> Jaxon.Path.encode([:root, "test", 0])
  {:ok, "$.test[0]"}
  ```

  How to handle encode errors:

  ```
  iex> Jaxon.Path.encode([:root, :whoops, "test", 0])
  {:error, "`:whoops` is not a valid JSON path segment"}
  ```
  """
  @spec encode(json_path) :: {:ok, String.t()} | {:error, String.t()}
  def encode(path) do
    case do_encode(path) do
      {:error, err} ->
        {:error, err}

      result ->
        {:ok, result}
    end
  end

  @doc ~S"""
  Parse path expressions:

  ```
  iex> Jaxon.Path.parse("$[*].pets[0]")
  {:ok, [:root, :all, "pets", 0]}
  ```

  How to handle parse errors;

  ```
  iex> Jaxon.Path.parse("$.test[x]")
  {:error, "Expected an integer at `x]`"}
  ```

  ```
  iex> Jaxon.Path.parse("$.\"test[x]")
  {:error, "Ending quote not found for string at `\"test[x]`"}
  ```
  """
  @spec parse(String.t()) :: {:ok, json_path} | {:error, String.t()}
  def parse(bin) do
    case parse_json_path(bin, "", []) do
      {:error, err} ->
        {:error, err}

      result ->
        {:ok, result}
    end
  end

  @doc ~S"""
  Parse path expressions:

  ```
  iex> Jaxon.Path.parse!("$[*].pets[0]")
  [:root, :all, "pets", 0]
  ```
  """
  @spec parse!(String.t()) :: json_path | no_return
  def parse!(bin) do
    case parse(bin) do
      {:error, err} ->
        raise ParseError, message: err

      {:ok, path} ->
        path
    end
  end

  @spec encode!(json_path) :: String.t() | no_return
  def encode!(path) do
    case do_encode(path) do
      {:error, err} ->
        raise ParseError, message: err

      result ->
        result
    end
  end

  defp add_key(_, acc = {:error, _}) do
    acc
  end

  defp add_key("*", acc) do
    [:all | acc]
  end

  defp add_key("$", acc) do
    [:root | acc]
  end

  defp add_key(k, acc) do
    [k | acc]
  end

  defp parse_string(<<?\\, ?", rest::binary>>, str) do
    parse_string(rest, <<str::binary, ?">>)
  end

  defp parse_string(<<?", rest::binary>>, str) do
    {str, rest}
  end

  defp parse_string("", _) do
    ""
  end

  defp parse_string(<<c, rest::binary>>, str) do
    parse_string(rest, <<str::binary, c>>)
  end

  defp parse_json_path(<<?\\, ?., rest::binary>>, cur, acc) do
    parse_json_path(rest, <<cur::binary, ?.>>, acc)
  end

  defp parse_json_path(<<?., rest::binary>>, "", acc) do
    parse_json_path(rest, "", acc)
  end

  defp parse_json_path(<<"[*]", rest::binary>>, "", acc) do
    [:all | parse_json_path(rest, "", acc)]
  end

  defp parse_json_path(<<?[, rest::binary>>, "", acc) do
    case Integer.parse(rest) do
      {i, <<?], rest::binary>>} ->
        [i | parse_json_path(rest, "", acc)]

      _ ->
        {:error, "Expected an integer at `#{String.slice(rest, 0, 10)}`"}
    end
  end

  defp parse_json_path(rest = <<?[, _::binary>>, cur, acc) do
    add_key(cur, parse_json_path(rest, "", acc))
  end

  defp parse_json_path(<<?., rest::binary>>, cur, acc) do
    add_key(cur, parse_json_path(rest, "", acc))
  end

  defp parse_json_path("", "", _) do
    []
  end

  defp parse_json_path("", cur, acc) do
    add_key(cur, acc)
  end

  defp parse_json_path(bin = <<?", rest::binary>>, "", acc) do
    case parse_string(rest, "") do
      {key, rest} ->
        [key | parse_json_path(rest, "", acc)]

      _ ->
        {:error, "Ending quote not found for string at `#{String.slice(bin, 0, 10)}`"}
    end
  end

  defp parse_json_path(<<c, rest::binary>>, cur, acc) do
    parse_json_path(rest, <<cur::binary, c>>, acc)
  end

  defp append_segment(err = {:error, _}, _) do
    err
  end

  defp append_segment(_, err = {:error, _}) do
    err
  end

  defp append_segment(s, rest = "[" <> _) do
    s <> rest
  end

  defp append_segment(s, "") do
    s
  end

  defp append_segment(s, rest) do
    s <> "." <> rest
  end

  defp do_encode_segment(:root) do
    "$"
  end

  defp do_encode_segment(:all) do
    "[*]"
  end

  defp do_encode_segment(i) when is_integer(i) do
    "[#{i}]"
  end

  defp do_encode_segment(s) when is_binary(s) do
    if(String.contains?(s, ["*", "$", "]", "[", ".", "\""])) do
      "\"#{String.replace(s, "\"", "\\\"")}\""
    else
      s
    end
  end

  defp do_encode_segment(s) do
    {:error, "`#{inspect(s)}` is not a valid JSON path segment"}
  end

  defp do_encode([]) do
    ""
  end

  defp do_encode([h]) do
    do_encode_segment(h)
  end

  defp do_encode([h | t]) do
    append_segment(do_encode_segment(h), do_encode(t))
  end
end
