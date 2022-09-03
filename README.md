# Jaxon :zap: [![Hex.pm](https://img.shields.io/hexpm/v/jaxon.svg)](https://hex.pm/packages/jaxon) [![Build Status](https://travis-ci.org/boudra/jaxon.svg?branch=master)](https://travis-ci.org/boudra/jaxon) [![Inline docs](http://inch-ci.org/github/boudra/jaxon.svg)](http://inch-ci.org/github/boudra/jaxon) [![Coverage Status](https://coveralls.io/repos/github/boudra/jaxon/badge.svg)](https://coveralls.io/github/boudra/jaxon)

**Jaxon** is a [fast JSON parser](#benchmarks) that can [stream](#streaming) any JSON document without holding it all in memory.

Jaxon fully conforms to the [RFC 8259](https://tools.ietf.org/html/rfc8259) and [ECMA 404](http://www.ecma-international.org/publications/standards/Ecma-404.htm) standards and is tested against [JSONTestSuite](https://github.com/nst/JSONTestSuite).

Roadmap:

- Make an alternative parser in Elixir, for those who don't want to use NIFs.
- JSON events to string Encoder.

Links:

- [Online documentation](https://hexdocs.pm/jaxon/)
- [Introduction to Jaxon](https://moboudra.com/intro-to-jaxon-json-parser-for-elixir/)
- [Benchmarks](https://boudra.github.io/jaxon/benchmark_results/decode.html)

---

[Click here if you want to use the 1.x version](https://github.com/boudra/jaxon/tree/fb638f76945236822e8e015ee4b4d79b8255b71e)

## Installation

```elixir
def deps do
  [
    {:jaxon, "~> 2.0"}
  ]
end
```

## Simple decoding

Decode a binary:

```elixir
iex> Jaxon.decode(~s({"jaxon":"rocks","array":[1,2]}))
{:ok, %{"array" => [1, 2], "jaxon" => "rocks"}}

iex> Jaxon.decode!(~s({"jaxon":"rocks","array":[1,2]}))
%{"array" => [1, 2], "jaxon" => "rocks"}
```

## Streaming

Jaxon can also query streams of JSON documents:

Query a binary JSON stream (notice how some items are incomplete JSON documents):

```elixir
iex> stream = [~s({"jaxon":"rocks","array":[1,2]}),~s({"jaxon":"rocks"), ~s(,"array":[3,4]})]
iex> stream |> Jaxon.Stream.from_enumerable() |> Jaxon.Stream.query([:root, "array", :all]) |> Enum.to_list()
[1, 2, 3, 4]
```

Query a binary JSON stream using JSON path expressions:

```elixir
iex> stream = [~s({"jaxon":"rocks","array":[1,2]})]
iex> stream |> Jaxon.Stream.from_enumerable() |> Jaxon.Stream.query(Jaxon.Path.parse!("$.array[*]")) |> Enum.to_list()
[1, 2]
```

Query a large file without holding the whole file in memory:

```elixir
"large_file.json"
|> File.stream!()
|> Jaxon.Stream.from_enumerable()
|> Jaxon.Stream.query([:root, "users", :all, "metadata"])
|> Stream.map(&[&1["username"],",",&1["email"],"\n"])
|> Stream.into(File.stream!("large_file.csv"))
|> Stream.run()
```

# JSON Path

You can either write your own like so:

`[:root, "users", 0, "name"]`

Or use the parser:

```elixir
iex> Jaxon.Path.parse!("$.array[*]")
[:root, "array", :all]
```

```elixir
iex> Jaxon.Path.parse!(~s($["key with spaces"][0]))
[:root, "key with spaces", 0]
```


## How does Jaxon work?

Jaxon first parses the JSON string into a list of events/tokens:

```elixir
iex(1)> Jaxon.Parsers.NifParser.parse(~s({"key":true}), [])
{:ok, [:start_object, {:string, "key"}, :colon, {:boolean, true}, :end_object]}
```

These are all the available events:

```elixir
:start_object
:end_object
:start_array
:end_array
{:string, binary}
{:integer, integer}
{:decimal, float}
{:boolean, boolean}
nil
{:incomplete, binary}
{:error, binary}
:colon
:comma
```

Which means that it can also parse a list of JSON tokens, even if the string is not a valid JSON representation:

```elixir
iex> Jaxon.Parser.parse(~s("this is a string" "another string"))
[{:string, "this is a string"}, {:string, "another string"}]
```

This makes it very flexible when decoding files and lets us use different implementations for parsers, at the moment the default parser is written in C as a NIF. It can be changed in the config like this:

```elixir
config :jaxon, :parser, Jaxon.Parsers.NifParser # only NifParser is supported at the moment
```

Then, the decoder's job is to take a list of events and aggregate it into a Elixir term:

```elixir
iex(4)> Jaxon.Decoders.Value.decode([:start_object, {:string, "key"}, :colon, {:boolean, true}
, :end_object])
{:ok, %{"key" => true}}
```

## About the NIF parser

All the parser does is take a binary and return a list of JSON events, the NIF respects the Erlang scheduler and tries to run for a maximum of one millisecond, yielding to the VM for another call if it runs over the limit.

## Benchmarks

Jaxon (using the NIF parser) performance is similar and often faster than **jiffy** and **jason**.

To run the benchmarks, execute:

```shell
mix bench.decode
```

See the decode benchmarks here: [benchmarks](https://boudra.github.io/jaxon/benchmark_results/decode.html)

## License

```
Copyright © 2018 Mohamed Boudra <mohamed@numidian.io>

This project is under the Apache 2.0 license. See the LICENSE file for more details.
```

Developed at [Konbert](https://konbert.com) for big data JSON parsing.
