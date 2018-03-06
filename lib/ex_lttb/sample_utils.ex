defmodule ExLTTB.SampleUtils do
  @moduledoc """
  Utility functions to perform common operations on generic samples
  """

  @doc """
  Returns the average sample of a list of sample.

  ## Arguments
  * `samples`: a list of samples. These can have any representation provided that access functions are provided (see Options)
  * `opts`: a keyword list of options

  ## Options
  * `sample_to_x_fun`: a function that takes as argument a sample and returns its x coordinate. Defaults to `sample[:x]`
  * `sample_to_y_fun`: a function that takes as argument a sample and returns its y coordinate. Defaults to `sample[:y]`
  * `xy_to_sample_fun`: a function that takes as argument `x` and `y` and returns a sample with these coordinates. Defaults to `%{x: x, y: y}`
  """
  def average_sample(samples, opts \\ []) when is_list(samples) do
    {x_sum, y_sum} = Enum.reduce(samples, {0, 0}, fn sample, {x_sum, y_sum} ->
      {x_sum + get_x(sample, opts), y_sum + get_y(sample, opts)}
    end)

    len = length(samples) / 1.0

    xy_to_sample(x_sum / len, y_sum / len, opts)
  end

  @doc """
  Returns the area of the triangle defined by `s1`, `s2` and `s3`.

  ## Arguments
  * `s1`, `s2`, `s3`: the vertices of the triangle. These can have any representation provided that access functions are provided (see Options)
  * `opts`: a keyword list of options

  ## Options
  * `sample_to_x_fun`: a function that takes as argument a sample and returns its x coordinate. Defaults to `sample[:x]`
  * `sample_to_y_fun`: a function that takes as argument a sample and returns its y coordinate. Defaults to `sample[:y]`
  * `xy_to_sample_fun`: a function that takes as argument `x` and `y` and returns a sample with these coordinates. Defaults to `%{x: x, y: y}`
  """
  def triangle_area(s1, s2, s3, opts) do
    x1 = get_x(s1, opts)
    y1 = get_y(s1, opts)

    x2 = get_x(s2, opts)
    y2 = get_y(s2, opts)

    x3 = get_x(s3, opts)
    y3 = get_y(s3, opts)

    abs((x1 - x3) * (y2 - y1) - (x1 - x2) * (y3 - y1)) / 2
  end

  defp get_x(sample, opts) do
    sample_to_x_fun = Keyword.get(opts, :sample_to_x_fun, fn sample -> sample[:x] end)

    sample_to_x_fun.(sample)
  end

  defp get_y(sample, opts) do
    sample_to_y_fun = Keyword.get(opts, :sample_to_y_fun, fn sample -> sample[:y] end)

    sample_to_y_fun.(sample)
  end

  defp xy_to_sample(x, y, opts) do
    xy_to_sample_fun = Keyword.get(opts, :xy_to_sample_fun, fn x, y -> %{x: x, y: y} end)

    xy_to_sample_fun.(x, y)
  end
end
