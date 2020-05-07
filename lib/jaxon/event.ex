defmodule Jaxon.Event do
  @type t ::
          :start_object
          | :end_object
          | :start_array
          | :end_array
          | {:string, binary}
          | {:integer, integer}
          | {:decimal, float}
          | {:boolean, boolean}
          | nil
          | {:incomplete, binary}
          | {:incomplete, {:integer, integer}, binary}
          | {:incomplete, {:decimal, float}, binary}
          | {:yield, [__MODULE__.t()], binary}
          | {:error, binary}
          | :colon
          | :comma
          | :end
end
