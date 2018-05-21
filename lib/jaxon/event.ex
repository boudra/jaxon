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
          | {:yield, [__MODULE__.t()], binary}
          | {:error, binary}
          | :end
end
