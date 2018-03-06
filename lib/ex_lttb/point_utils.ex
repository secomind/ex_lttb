defmodule ExLTTB.PointUtils do
  @moduledoc """
  Utility functions to perform common operations on generic points
  """

  @doc """
  Returns the average point of a list of point.

  ## Arguments
  * `points`: a list of points. These can have any representation provided that access functions are provided (see Options)
  * `opts`: a keyword list of options

  ## Options
  * `point_to_x_fun`: a function that takes as argument a point and returns its x coordinate. Defaults to `point[:x]`
  * `point_to_y_fun`: a function that takes as argument a point and returns its y coordinate. Defaults to `point[:y]`
  * `xy_to_point_fun`: a function that takes as argument `x` and `y` and returns a point with these coordinates. Defaults to `%{x: x, y: y}`
  """
  def average_point(points, opts \\ []) when is_list(points) do
    {x_sum, y_sum} = Enum.reduce(points, {0, 0}, fn point, {x_sum, y_sum} ->
      {x_sum + get_x(point, opts), y_sum + get_y(point, opts)}
    end)

    len = length(points) / 1.0

    xy_to_point(x_sum / len, y_sum / len, opts)
  end

  defp get_x(point, opts) do
    point_to_x_fun = Keyword.get(opts, :point_to_x_fun, fn point -> point[:x] end)

    point_to_x_fun.(point)
  end

  defp get_y(point, opts) do
    point_to_y_fun = Keyword.get(opts, :point_to_y_fun, fn point -> point[:y] end)

    point_to_y_fun.(point)
  end

  defp xy_to_point(x, y, opts) do
    xy_to_point_fun = Keyword.get(opts, :xy_to_point_fun, fn x, y -> %{x: x, y: y} end)

    xy_to_point_fun.(x, y)
  end
end
