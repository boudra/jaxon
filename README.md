# Jaxon

Jaxon is an efficient and simple SAX-based JSON parser for Elixir, it's main goal is to be able to parse huge JSON files with minimal memory footprint.


## Installation

```elixir
def deps do
  [
    {:jaxon, "~> 0.1.0"}
  ]
end
```

## How to use

### Event-based parsing

```elixir
decoder =
    Jaxon.make_decoder()
    |> Jaxon.update_decoder("{\"jaxon\":\"rocks\",\"array\":[1,2]}")

# every decode/1 call with return a different parsing event
Jaxon.decode(decoder)

# The events will be:

# :start_object
# {:key, "jaxon"}
# {:string, "rocks"}
# {:key, "array"}
# :start_array
# {:integer, 1}
# {:integer, 2}
# :end_array
# :end_object
# :end
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
