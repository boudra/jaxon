[![Hex.pm](https://img.shields.io/hexpm/v/jaxon.svg)](https://hex.pm/packages/jaxon)

------------------------------------

# Jaxon

**Jaxon** is an efficient and simple SAX-based JSON parser for Elixir, it's main goal is to be able to parse **JSON data of any size** with a **very small memory** footprint.

[Online documentation](https://hexdocs.pm/jaxon/)

## :muscle:   Features

* **Event based parsing:** Parses data as it comes, no need to hold everything in memory, perfect for consuming large JSON streams of any size
* **Pausable partial parsing:** Pass a portion of your JSON and then resume parsing when you have the rest
* **No schema restrictions:** It only decodes JSON to Erlang terms


## :running:  To do

* **Reading with JSON path:** Make an Elixir stream from a list of JSON path expressions.
* **Better and more informative errors**
* **Unicode support in strings**
* **Benchmarking**
* **JSON encoding?**

## :rocket:  Installation

```elixir
def deps do
  [
    {:jaxon, "~> 0.1.0"} # or {:jaxon, git: "https://github.com/boudra/jaxon.git", ref: "master"}
  ]
end
```

## :thinking:  How to use it

### Decode a binary into events

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

### Partial decoding

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

## License

```
Copyright © 2018 Mohamed Boudra <mohamed@boudra.me>

This project is under the Apache 2.0 license. See the LICENSE file for more details.
```

Developed at [Sqlify.io](https://sqlify.io) for big data JSON parsing.
