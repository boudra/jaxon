defmodule Jason.JsonTestSuite do
  use ExUnit.Case, async: true

  @json_test_suite_path "json_test_suite"

  "#{@json_test_suite_path}/*.json"
  |> Path.wildcard()
  |> Enum.each(fn
    file = "json_test_suite/n_" <> name ->
      test name do
        assert {:error, _} = Jaxon.decode(File.read!(unquote(file)))
      end

    file = "json_test_suite/y_" <> name ->
      test name do
        assert {:ok, _} = Jaxon.decode(File.read!(unquote(file)))
      end

    file = "json_test_suite/i_" <> name ->
      test name do
        assert {:ok, _} = Jaxon.decode(File.read!(unquote(file)))
      end
  end)
end
