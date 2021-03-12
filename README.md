# ExJsonPath

ExJsonPath is an Elixir library which allows to query maps (JSON objects) and lists (JSON arrays),
using [JSONPath](https://goessner.net/articles/JsonPath/) expressions.

ExJsonPath is not limited to JSON, but allows to query nearly any kind of map or list, with just
one main restriction: keys have to be strings.

## Installation
- Add `ExJsonPath` dependency to your project's `mix.exs`:

```elixir
def deps do
  [
    {:exjsonpath, "~> 0.1"}
  ]
end
```
- Run `mix deps.get`

## Basic Usage

```elixir
iex(1)> ExJSONPath.eval([%{"v" => 1}, %{"v" => 2}, %{"v" => 3}], "$[?(@.v > 1)].v")
{:ok, [2, 3]}
```

```elixir
iex(1)> {:ok, json} = File.read("store.json")
iex(2)> {:ok, store} = Jason.decode(json)
iex(3)> ExJSONPath.eval(store, "$.store.book[?(@.price > 20)].title")
{:ok, ["The Lord of the Rings"]}
```

Full documentation can be found at [hexdocs.pm/exjsonpath](https://hexdocs.pm/exjsonpath).

## About This Project

This project has been created in order to provide support to JSONPath to [Astarte Flow](https://github.com/astarte-platform/astarte_flow).
We are open to any contribution and we encourage adoption of this library to anyone looking for a maps and lists query language.
