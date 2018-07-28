# Jaxon :zap: [![Hex.pm](https://img.shields.io/hexpm/v/jaxon.svg)](https://hex.pm/packages/jaxon) [![Build Status](https://travis-ci.org/boudra/jaxon.svg?branch=master)](https://travis-ci.org/boudra/jaxon) [![Inline docs](http://inch-ci.org/github/boudra/jaxon.svg)](http://inch-ci.org/github/boudra/jaxon) [![Coverage Status](https://coveralls.io/repos/github/boudra/jaxon/badge.svg)](https://coveralls.io/github/boudra/jaxon)

**Jaxon** is the [fastest JSON parser](#benchmarks) that can [stream](#streaming) any JSON document without holding it all in memory.

Jaxon fully conforms to the [RFC 8259](https://tools.ietf.org/html/rfc8259) and [ECMA 404](http://www.ecma-international.org/publications/standards/Ecma-404.htm) standards and is tested against [JSONTestSuite](https://github.com/nst/JSONTestSuite).

Roadmap:

- Make an alternative parser in Elixir, for those who don't want to use NIFs.
- JSON events to string Encoder.

[Online documentation](https://hexdocs.pm/jaxon/)

---

## Installation

```elixir
def deps do
  [
    {:jaxon, "~> 1.0"}
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

Query a binary JSON stream:

```elixir
iex> stream = [~s({"jaxon":"rocks","array":[1,2]})]
iex> stream |> Jaxon.Stream.query([:root, "array", :all]) |> Enum.to_list()
[1, 2]
```

Query a binary JSON stream using JSON path expressions:

```elixir
iex> stream = [~s({"jaxon":"rocks","array":[1,2]})]
iex> stream |> Jaxon.Stream.query(Jaxon.Path.decode!("$.array[*]")) |> Enum.to_list()
[1, 2]
```

Query a large file without holding the whole file in memory:

```elixir
"large_file.json"
|> File.stream!()
|> Jaxon.Stream.query([:root, "users", :all, "id"])
|> Enum.to_list()
```

## Events

Everything that Jaxon does is based on parsed JSON events like these:

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
:end
```

Which make it very flexible when decoding files and lets us use different implementations for parsers, at the moment the default parser is written in C as a NIF.

```elixir
config :jaxon, :parser, Jaxon.Parsers.NifParser # only NifParser is supported at the moment
```

The parser takes a binary and returns a list of events:

```elixir
iex> Jaxon.Parser.parse(~s({"key":2}))
[:start_object, {:string, "key"}, :colon, {:integer, 2}, :end_object, :end]
```

Which means that it can also parse a list of JSON tokens, event if the string is not a valid JSON representation:

```elixir
iex> Jaxon.Parser.parse(~s("this is a string" "another string"))
[{:string, "this is a string"}, {:string, "another string"}, :end]
```

## Nif parser

The NIF parser is in C and all it does is take a binary and return a list of JSON events, the NIF respects the Erlang scheduler and tries to run for a maximum of one millisecond, yielding to the VM for another call if it runs over the limit.

## Benchmarks

Jaxon (using the NIF parser) performance is similar and often faster than _jiffy_ and _jason_.

To run the benchmarks, execute:

```shell
mix bench.decode
```

## License

```
Copyright © 2018 Mohamed Boudra <mohamed@boudra.me>

This project is under the Apache 2.0 license. See the LICENSE file for more details.
```

Developed at [Sqlify.io](https://sqlify.io) for big data JSON parsing.
