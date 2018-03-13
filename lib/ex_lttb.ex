# Copyright (c) 2018 Ispirata Srl
#
# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation
# files (the "Software"), to deal in the Software without
# restriction, including without limitation the rights to use,
# copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following
# conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.

defmodule ExLTTB do
  @moduledoc """
  Documentation for ExLTTB.
  """

  alias ExLTTB.SampleUtils

  @doc """
  Downsamples a sample list using [LTTB](https://skemman.is/bitstream/1946/15343/3/SS_MSthesis.pdf).

  ## Arguments
  * `sample_list`: a `List` of samples. These can have any representation provided that access functions are provided (see Options). The samples are assumed to be sorted by the `x` coordinate.
  * `threshold`: the number of required output samples. Must be >= 2.
  * `opts`: a keyword list of options.

  ## Options
  * `sample_to_x_fun`: a function that takes as argument a sample and returns its x coordinate. Defaults to `sample[:x]`
  * `sample_to_y_fun`: a function that takes as argument a sample and returns its y coordinate. Defaults to `sample[:y]`
  * `xy_to_sample_fun`: a function that takes as argument `x` and `y` and returns a sample with these coordinates. Defaults to `%{x: x, y: y}`

  ## Return
  * `{:ok, sample_list}` where sample_list is a downsampled list of samples.
  * `{:error, reason}`
  """
  def downsample_to(sample_list, threshold, opts \\ [])

  def downsample_to(_sample_list, threshold, _opts) when threshold < 2 do
    {:error, :invalid_threshold}
  end

  def downsample_to([first_sample | _tail] = sample_list, threshold, _opts)
      when threshold == 2 and length(sample_list) >= 2 do
    {:ok, [first_sample, List.last(sample_list)]}
  end

  def downsample_to(sample_list, threshold, _opts) when threshold > length(sample_list) do
    {:ok, sample_list}
  end

  def downsample_to(sample_list, threshold, opts) do
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
    avg = (length(sample_list) - 2) / (buckets_number - 2)

    # The acc is populated from right to left and reversed at the end
    do_make_buckets(tail, 1, avg, avg, [[second_sample], [first_sample]])
  end

  defp do_make_buckets([head | []], _current_index, _avg, _avg_acc, buckets_acc) do
    Enum.reverse([[head] | buckets_acc])
  end

  defp do_make_buckets(
         [head | tail],
         current_index,
         avg,
         avg_acc,
         [bucket_head | bucket_tail] = buckets_acc
       ) do
    next_index = current_index + 1

    if current_index > avg_acc do
      do_make_buckets(tail, next_index, avg, avg_acc + avg, [[head] | buckets_acc])
    else
      do_make_buckets(tail, next_index, avg, avg_acc, [[head | bucket_head] | bucket_tail])
    end
  end

  defp select_samples([[first_sample] | tail] = _buckets, opts) do
    do_select_samples(tail, [first_sample], opts)
  end

  defp do_select_samples([[last_sample] | []], acc, _opts) do
    Enum.reverse([last_sample | acc])
  end

  defp do_select_samples([candidates, next_bucket | tail], [prev_sample | _acc_tail] = acc, opts) do
    next_sample = SampleUtils.average_sample(next_bucket, opts)

    [initial_candidate | _tail] = candidates
    initial_area = SampleUtils.triangle_area(prev_sample, initial_candidate, next_sample, opts)

    {selected_sample, _area} =
      Enum.reduce(candidates, {initial_candidate, initial_area}, fn candidate_sample,
                                                                    {best_sample, best_area} ->
        candidate_area =
          SampleUtils.triangle_area(prev_sample, candidate_sample, next_sample, opts)

        if candidate_area > best_area do
          {candidate_sample, candidate_area}
        else
          {best_sample, best_area}
        end
      end)

    do_select_samples([next_bucket | tail], [selected_sample | acc], opts)
  end
end
