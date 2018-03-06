defmodule ExLTTB do
  @moduledoc """
  Documentation for ExLTTB.
  """

  alias ExLTTB.PointUtils

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

  defp select_samples([[first_sample] | tail] = _buckets, opts) do
    do_select_samples(tail, [first_sample], opts)
  end

  defp do_select_samples([[last_sample] | []], acc, _opts) do
    Enum.reverse([last_sample | acc])
  end

  defp do_select_samples([candidates, next_bucket | tail], [prev_point | _acc_tail] = acc, opts) do
    next_point = PointUtils.average_point(next_bucket, opts)

    [initial_candidate | _tail] = candidates
    initial_area = PointUtils.triangle_area(prev_point, initial_candidate, next_point, opts)

    {selected_point, _area} =
      Enum.reduce(candidates, {initial_candidate, initial_area}, fn candidate_point, {best_point, best_area} ->
        candidate_area = PointUtils.triangle_area(prev_point, candidate_point, next_point, opts)
        if candidate_area > best_area do
          {candidate_point, candidate_area}
        else
          {best_point, best_area}
        end
      end)

    do_select_samples([next_bucket | tail], [selected_point | acc], opts)
  end
end
