[![Hex.pm](https://img.shields.io/hexpm/v/jaxon.svg)](https://hex.pm/packages/jaxon)

------------------------------------

# Jaxon

Jaxon is an efficient and simple SAX-based JSON parser for Elixir, it's main goal is to be able to parse huge JSON files with minimal memory footprint.

## :rocket:  Installation

```elixir
def deps do
  [
    {:jaxon, "~> 0.1.0"} # or {:jaxon, git: "https://github.com/boudra/jaxon.git", ref: "master"}
  ]
end
```

## :thinking:  How to use

### Event-based parsing

```elixir
decoder =
    Jaxon.make_decoder()
    |> Jaxon.update_decoder("{\"jaxon\":\"rocks\",\"array\":[1,2]}")

# every decode/1 call with return a different parsing event
iex> Jaxon.decode(decoder)

# For the passed binary, the events will be:

iex> Jaxon.consume(decoder)
[
:start_object,
{:key, "jaxon"},
{:string, "rocks"},
{:key, "array"},
:start_array,
{:integer, 1},
{:integer, 2},
:end_array,
:end_object,
:end
]
```

### Partial parsing

This is very useful when you're streaming JSON from the network or disk.

```elixir
iex> d = Jaxon.make_decoder()
iex> d = Jaxon.update_decoder(d, "{\"whoo")

iex> d = Jaxon.decode(d)
:start_object

iex> {:incomplete, rest} = Jaxon.decode(d)
{:incomplete, "\"whoo"}

iex> d = Jaxon.update_decoder(d, rest <> "ps\":\":)\"}")
iex> Jaxon.decode(d)
{:key, "whoops"}

iex> Jaxon.decode(d)
{:string, ":)"}

iex> Jaxon.decode(d)
:end_object

iex> Jaxon.decode(d)
:end
```

### Possible events returned


```elixir
:start_object
:end_object
:start_array
:end_array
{:key, binary}
{:string, binary}
{:integer, integer}
{:decimal, float}
{:boolean, boolean}
nil
{:incomplete, binary}
:end
:error
```
