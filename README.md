[![Hex.pm](https://img.shields.io/hexpm/v/jaxon.svg)](https://hex.pm/packages/jaxon)

------------------------------------

# Jaxon

**Jaxon** can parse **terabytes of JSON** with a **very small memory** footprint, as fast as possible.

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
iex> Jaxon.Stream.query([~s({"jaxon":"rocks","array":[1,2]})], "$.jaxon") |> Enum.to_list()
["rocks"]
```

Query a large file without holding the whole file in memory:

```elixir
"large_file.json"
|> File.stream!()
|> Jaxon.Stream.query("$.users.id")
|> Enum.to_list()
```

### Event decoder

Jaxon's core decoder is written in C and all it does is receive a binary and it returns a list of events, like:

```elixir
iex> Jaxon.Decoder.decode(~s({"key":2}))
[:start_object, {:string, "key"}, {:integer, 2}, :end_object, :end]
```

Which means that it can also parse a list of JSON tokens:

```elixir
iex> Jaxon.Decoder.decode(~s("this is a string" "another string"))
[{:string, "this is a string"}, {:string, "another string"}, :end]
```

## License

```
Copyright © 2018 Mohamed Boudra <mohamed@boudra.me>

This project is under the Apache 2.0 license. See the LICENSE file for more details.
```

Developed at [Sqlify.io](https://sqlify.io) for big data JSON parsing.
