# ExLTTB [![hex.pm version](https://img.shields.io/hexpm/v/ex_lttb.svg)](https://hex.pm/packages/ex_lttb) [![Build Status](https://travis-ci.org/ispirata/ex_lttb.svg?branch=master)](https://travis-ci.org/ispirata/ex_lttb) [![Coverage Status](https://coveralls.io/repos/github/ispirata/ex_lttb/badge.svg)](https://coveralls.io/github/ispirata/ex_lttb)

An Elixir downsampling library that retains the visual characteristics of your data.

ExLTTB is based on [Largest-Triangle-Three-Buckets](https://skemman.is/handle/1946/15343) (LTTB) and it contains two implementation modules: `ExLTTB` implements the original algorithm using `Enum` and eager evaluation, `ExLTTB.Stream` implements a slightly modified version to cope with lazy evaluation and using `Stream`.

The data is assumed to be ordered by its x coordinate in both implementations.

## Installation

Add `ex_lttb` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_lttb, "~> 0.3.0"}
  ]
end
```

## Documentation

You can read the documentation on [HexDocs](https://hexdocs.pm/ex_lttb).

## Examples

```elixir
# Downsample a list of data in the default shape of %{x: x, y: y}
input_samples = for x <- 1..100, do: %{x: x, y: :random.uniform() * 100}

# 30 output samples
output_samples = ExLTTB.downsample_to(input_samples, 30)

# Downsample a list of data of arbitrary shape
input_samples =
  for x <- 1..100 do
    %{nested: %{timebase: x},
      data: :random.uniform() * 100,
      untouched_other_key: :random.uniform() * 3
    }
  end

sample_to_x_fun = fn sample -> sample[:nested][:timebase] end
sample_to_y_fun = fn sample -> sample[:data] end
xy_to_sample_fun = fn x, y -> %{nested: %{timebase: x}, data: y} end

output_samples =
  ExLTTB.downsample_to(
    input_samples,
    30,
    sample_to_x_fun: sample_to_x_fun,
    sample_to_y_fun: sample_to_y_fun,
    xy_to_sample_fun: xy_to_sample_fun
  )

# Downsample a stream of data
input_stream =
  Stream.iterate(%{x: 0, y: :random.uniform() * 100}, fn %{x: x} -> %{x: x + 1, y: :random.uniform() * 100} end)

# Downsample rate of 2.3
output_samples = ExLTTB.Stream.downsample(input_stream, 2.3) |> Enum.take(20)

# The options for arbitrary shaped data are the same for the streaming version
```
