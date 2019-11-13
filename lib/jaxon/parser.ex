defmodule Jaxon.Parser do
  @parser Application.get_env(:jaxon, :parser, Jaxon.Parsers.NifParser)

  @callback parse(String.t(), Keyword.t()) ::
              {:ok, [Jaxon.Event.t()]}
              | {:error, Jaxon.ParseError.t()}
              | {:incomplete, String.t()}

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
  """

  @spec parse(String.t(), Keyword.t()) ::
          {:ok, [Jaxon.Event.t()]}
          | {:error, Jaxon.ParseError.t()}
          | {:incomplete, [Jaxon.Event.t()], String.t()}
  defdelegate parse(events, opts \\ []), to: @parser
end
