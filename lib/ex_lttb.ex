defmodule ExLTTB do
  @moduledoc """
  Documentation for ExLTTB.
  """

  def lttb(sample_list, threshold, opts \\ [])

  def lttb(_sample_list, threshold, _opts) when threshold < 2 do
    {:error, :invalid_threshold}
  end

  def lttb([first_sample | _tail] = sample_list, threshold, _opts) when threshold == 2 and length(sample_list) >= 2 do
    {:ok, [first_sample, List.last(sample_list)]}
  end

  def lttb(sample_list, threshold, _opts) when threshold > length(sample_list) do
    {:ok, sample_list}
  end

  def lttb(sample_list, threshold, opts) do
    samples =
      make_buckets(sample_list, threshold)
      |> select_samples(opts)

    {:ok, samples}
  end

  defp make_buckets(sample_list, buckets_number) when buckets_number > length(sample_list) do
    Enum.map(sample_list, fn el -> [el] end)
  end

  defp make_buckets([first_sample, second_sample | tail] = sample_list, buckets_number) do
    # We subtract 2 since the first and last buckets are fixed,
    # containing the first and last sample
    avg = (length(sample_list) - 2) / (buckets_number -  2)

    # The acc is populated from right to left and reversed at the end
    do_make_buckets(tail, 1, avg, avg, [[second_sample], [first_sample]])
  end

  defp do_make_buckets([head | []], _current_index, _avg, _avg_acc, buckets_acc) do
    Enum.reverse([[head] | buckets_acc])
  end

  defp do_make_buckets([head | tail], current_index, avg, avg_acc, [bucket_head | bucket_tail] = buckets_acc) do
    next_index =  current_index + 1
    if Float.floor(avg_acc) > current_index do
      do_make_buckets(tail, next_index, avg, avg_acc, [[head | bucket_head] | bucket_tail])
    else
      do_make_buckets(tail, next_index, avg,  avg_acc + avg, [[head] | buckets_acc])
    end
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

  defp average_point(points, opts) do
    {x_sum, y_sum} = Enum.reduce(points, {0, 0}, fn point, {x_sum, y_sum} -> {x_sum + get_x(point, opts), y_sum + get_y(point, opts)} end)
    len = length(points)

    xy_to_point(x_sum / len, y_sum / len, opts)
  end

  defp triangle_area(p1, p2, p3, opts) do
    x1 = get_x(p1, opts)
    y1 = get_y(p1, opts)

    x2 = get_x(p2, opts)
    y2 = get_y(p2, opts)

    x3 = get_x(p3, opts)
    y3 = get_y(p3, opts)

    abs((x1 - x3) * (y2 - y1) - (x1 - x2) * (y3 - y1)) / 2
  end

  defp select_samples([[first_sample] | tail] = _buckets, opts) do
    do_select_samples(tail, [first_sample], opts)
  end

  defp do_select_samples([[last_sample] | []], acc, _opts) do
    Enum.reverse([last_sample | acc])
  end

  defp do_select_samples([candidates, next_bucket | tail], [prev_point | _acc_tail] = acc, opts) do
    next_point = average_point(next_bucket, opts)

    [initial_candidate | _tail] = candidates
    initial_area = triangle_area(prev_point, initial_candidate, next_point, opts)

    {selected_point, _area} =
      Enum.reduce(candidates, {initial_candidate, initial_area}, fn candidate_point, {best_point, best_area} ->
        candidate_area = triangle_area(prev_point, candidate_point, next_point, opts)
        if candidate_area > best_area do
          {candidate_point, candidate_area}
        else
          {best_point, best_area}
        end
      end)

    do_select_samples([next_bucket | tail], [selected_point | acc], opts)
  end
end
