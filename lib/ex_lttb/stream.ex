defmodule ExLTTB.Stream do
  @moduledoc """
  ExLTTB with lazy evalutation
  """

  alias ExLTTB.PointUtils

  defp make_buckets(samples_stream, avg_bucket_size, opts) when is_integer(avg_bucket_size) do
    make_buckets(samples_stream, avg_bucket_size / 1, opts)
  end

  defp make_buckets(samples_stream, avg_bucket_size, opts) do
    # chunk_fun and after_fun use these
    # Accumulator: {curr_idx, avg_acc, next_bucket_acc, ready_bucket}
    # Emitted data: a Stream of [{[sample | samples] = bucket, next_bucket_avg_point}]
    # This way in the next step we can choose the candidate point with a single Stream element
    # The extra list wrapping of the elements is needed to be able to emit multiple chunks in after_fun, flat_mapping afterwards

    chunk_fun = fn
      first_sample, {0, 0, [], []} ->
        {:cont, {1, avg_bucket_size, [], [first_sample]}}

      sample, {current_index, avg_acc, bucket_acc, ready_bucket} ->
        next_index = current_index + 1
        if current_index > avg_acc do
          new_ready_bucket = Enum.reverse([sample | bucket_acc])
          new_ready_bucket_avg_point = PointUtils.average_point(new_ready_bucket, opts)
          {:cont, [{ready_bucket, new_ready_bucket_avg_point}], {next_index, avg_acc + avg_bucket_size, [], new_ready_bucket}}
        else
          {:cont, {next_index, avg_acc, [sample | bucket_acc], ready_bucket}}
        end
    end

    after_fun = fn
      {_current_index, _avg_acc, [], [last_sample | ready_bucket_tail]} ->
        {:cont, [{ready_bucket_tail, last_sample}, {last_sample, nil}], []}

      {_current_index, _avg_acc, [last_sample | []], ready_bucket} ->
        {:cont, [{ready_bucket, last_sample}, {last_sample, nil}], []}

      {_current_index, _avg_acc, [last_sample | bucket_acc_tail], ready_bucket} ->
        last_bucket = Enum.reverse(bucket_acc_tail)
        last_bucket_avg_point = PointUtils.average_point(bucket_acc_tail, opts)
        {:cont, [{ready_bucket, last_bucket_avg_point}, {last_bucket, last_sample}, {[last_sample], nil}], []}
    end

    Stream.chunk_while(samples_stream, {0, 0, [], []}, chunk_fun, after_fun)
    |> Stream.flat_map(fn x -> x end)
  end

  defp select_samples(samples_stream, opts) do
    Stream.transform(samples_stream, nil, fn
      {[first_sample | []], _next_samples_avg_point}, nil ->
        {[first_sample], first_sample}

      {[last_sample | []], nil}, _prev_sample ->
        {[last_sample], last_sample}

      {[initial_candidate | candidates_tail], next_samples_avg}, prev_sample ->
        initial_area = PointUtils.triangle_area(prev_sample, initial_candidate, next_samples_avg, opts)

        {selected_point, _selected_area} =
          Enum.reduce(candidates_tail, {initial_candidate, initial_area}, fn candidate_point, {best_point, best_area} ->
            candidate_area = PointUtils.triangle_area(prev_sample, candidate_point, next_samples_avg, opts)
            if candidate_area > best_area do
              {candidate_point, candidate_area}
            else
              {best_point, best_area}
            end
          end)

        {[selected_point], selected_point}
    end)
  end
end
