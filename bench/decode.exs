decode_jobs = %{
  "Jaxon" => fn json -> Jaxon.decode!(json) end,
  "jiffy" => fn json -> :jiffy.decode(json, [:return_maps, :use_nil]) end,
  "Jason" => fn json -> Jason.decode!(json) end,
  "Poison" => fn json -> Poison.decode!(json) end
}

decode_inputs = [
  "GitHub",
  "Giphy",
  "GovTrack",
  "Blockchain",
  "Pokedex",
  "JSON Generator",
  "JSON Generator (Pretty)",
  "UTF-8 escaped",
  "UTF-8 unescaped",
  "Issue 90"
]

read_data = fn name ->
  file =
    name
    |> String.downcase()
    |> String.replace(~r/([^\w]|-|_)+/, "-")
    |> String.trim("-")

  File.read!(Path.expand("data/#{file}.json", __DIR__))
end

inputs = for name <- decode_inputs, into: %{}, do: {name, read_data.(name)}

Benchee.run(
  decode_jobs,
  parallel: 1,
  warmup: 2,
  time: 5,
  inputs: inputs,
  formatters: [
    &Benchee.Formatters.HTML.output/1,
    &Benchee.Formatters.Console.output/1
  ],
  formatter_options: [
    console: %{comparison: true},
    html: %{
      file: Path.expand("output/decode.html", __DIR__)
    }
  ]
)
