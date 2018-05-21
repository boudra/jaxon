[![Hex.pm](https://img.shields.io/hexpm/v/jaxon.svg)](https://hex.pm/packages/jaxon)

------------------------------------

# Jaxon

**Jaxon** can parse **huge JSON documents** with a **very small memory** footprint, as fast as possible.

[Online documentation](https://hexdocs.pm/jaxon/)

## :rocket:  Installation

```elixir
def deps do
  [{:jaxon, "~> 1.0.0"}]
end
```

## :thinking:  How to use it

### Decode a JSON binary

```elixir
iex(1)> Jaxon.decode!(~s({"jaxon":"rocks","array":[1,2]}))
%{"array" => [1, 2], "jaxon" => "rocks"}
```

```elixir
iex> Jaxon.decode(~s({"jaxon":"rocks","array":[1,2]}))
{:ok, %{"array" => [1, 2], "jaxon" => "rocks"}}
```

### JSON path querying

Query a binary stream using JSON path expressions:

```elixir
iex> stream = [~s({"jaxon":"rocks","array":[1,2]})]
iex> stream |> Jaxon.Stream.query("$.jaxon") |> Enum.to_list()
["rocks"]
```

Query a large file without holding the whole file in memory:

```elixir
"large_file.json"
|> File.stream!()
|> Jaxon.Stream.query("$.users.id")
|> Enum.to_list()
```

### Events

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

Which make it very flexible when decoding files and lets us use different implementations for parsers, at the moment the default parser is written in C as a NIF, a native parser written in Elixir is planned.

```elixir
config :jaxon, :parser, Jaxon.Parsers.NifParser # only NifParser is supported at the moment
```

The parser takes a binary and returns a list of events:

```elixir
iex> Jaxon.Parser.parse(~s({"key":2}))
[:start_object, {:string, "key"}, {:integer, 2}, :end_object, :end]
```

Which means that it can also parse a list of JSON tokens, event if the string is not a valid JSON representation:

```elixir
iex> Jaxon.Parser.parse(~s("this is a string" "another string"))
[{:string, "this is a string"}, {:string, "another string"}, :end]
```

## License

```
Copyright © 2018 Mohamed Boudra <mohamed@boudra.me>

This project is under the Apache 2.0 license. See the LICENSE file for more details.
```

Developed at [Sqlify.io](https://sqlify.io) for big data JSON parsing.
