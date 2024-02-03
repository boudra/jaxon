defmodule Jaxon.Parser do
  @parser Application.compile_env(:jaxon, :parser, Jaxon.Parsers.NifParser)

  @type parse_return() ::
          {:ok, list(Jaxon.Event.t())}
          | {:incomplete, list(Jaxon.Event.t()), String.t()}
          | {:error, Jaxon.ParseError.t()}

  @callback parse(String.t(), Keyword.t()) :: parse_return()

  @moduledoc ~S"""
  ## Example

  Call `parse/1` get a list of parsed events:

  *Note that keys are treated as the same as strings*

  ```
  iex> Jaxon.Parser.parse("{\"jaxon\":\"rocks\",\"array\":[1,2]}")
  {:ok, [
   :start_object,
   {:string, "jaxon"},
   :colon,
   {:string, "rocks"},
   :comma,
   {:string, "array"},
   :colon,
   :start_array,
   {:integer, 1},
   :comma,
   {:integer, 2},
   :end_array,
   :end_object
  ]}
  ```

  ```
  iex> Jaxon.Parser.parse(~s(2, 3  true null "incomplete string))
  {:incomplete, [
   {:integer, 2},
   :comma,
   {:integer, 3},
   {:boolean, true},
    nil,
  ], "\"incomplete string"}
  ```
  """

  @spec parse(String.t()) :: parse_return()
  @spec parse(String.t(), Keyword.t()) :: parse_return()
  defdelegate parse(events, opts \\ []), to: @parser
end
