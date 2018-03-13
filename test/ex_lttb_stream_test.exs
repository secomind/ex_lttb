defmodule ExLTTB.StreamTest do
  use ExUnit.Case
  use ExUnitProperties
  doctest ExLTTB.Stream

  property "resulting list has always correct length" do
    ordered_sample_list_gen =
      gen all sample_list <- list_of(fixed_map(%{x: float(), y: float()}), min_length: 2) do
        Enum.sort(sample_list, fn %{x: xa}, %{x: xb} -> xa <= xb end)
      end

    check all sample_list <- ordered_sample_list_gen,
              avg_bucket_size <- float(min: 1.0) do
      result =
        ExLTTB.Stream.downsample(sample_list, avg_bucket_size)
        |> Enum.to_list()

      assert length(result) <=
               min(length(sample_list), 2 + Float.ceil(length(sample_list) / avg_bucket_size))
    end
  end

  property "the samples in the result are contained in the original list (including additional fields)" do
    ordered_sample_list_gen =
      gen all sample_list <- list_of(fixed_map(%{x: float(), y: float()}), min_length: 2) do
        Enum.sort(sample_list, fn %{x: xa}, %{x: xb} -> xa <= xb end)
      end

    check all sample_list <- ordered_sample_list_gen,
              avg_bucket_size <- float(min: 1.0, max: length(sample_list)) do
      result =
        ExLTTB.Stream.downsample(sample_list, avg_bucket_size)
        |> Enum.to_list()

      assert Enum.all?(result, fn el -> Enum.member?(sample_list, el) end)
    end
  end

  property "the first and last sample are the same of the original list" do
    ordered_sample_list_gen =
      gen all sample_list <- list_of(fixed_map(%{x: float(), y: float()}), min_length: 2) do
        Enum.sort(sample_list, fn %{x: xa}, %{x: xb} -> xa <= xb end)
      end

    check all sample_list <- ordered_sample_list_gen,
              avg_bucket_size <- float(min: 1.0, max: length(sample_list)) do
      result =
        ExLTTB.Stream.downsample(sample_list, avg_bucket_size)
        |> Enum.to_list()

      assert List.first(result) == List.first(sample_list)
      assert List.last(result) == List.last(sample_list)
    end
  end

  property "returns the same stream if avg_bucket_size == 1" do
    ordered_sample_list_gen =
      gen all sample_list <- list_of(fixed_map(%{x: float(), y: float()}), min_length: 2) do
        Enum.sort(sample_list, fn %{x: xa}, %{x: xb} -> xa <= xb end)
      end

    check all sample_list <- ordered_sample_list_gen do
      avg_bucket_size = 1
      result = ExLTTB.Stream.downsample(sample_list, avg_bucket_size)
      assert result == sample_list
    end
  end

  property "integer avg_bucket_size is correctly converted" do
    greater_than_one_gen = gen all int <- positive_integer(), do: int + 1
    ordered_sample_list_gen =
      gen all sample_list <- list_of(fixed_map(%{x: float(), y: float()}), min_length: 2) do
        Enum.sort(sample_list, fn %{x: xa}, %{x: xb} -> xa <= xb end)
      end

    check all sample_list <- ordered_sample_list_gen,
              avg_bucket_size <- greater_than_one_gen do
      result =
        ExLTTB.Stream.downsample(sample_list, avg_bucket_size)
        |> Enum.to_list()

      assert length(result) <=
               min(length(sample_list), 2 + Float.ceil(length(sample_list) / avg_bucket_size))
    end
  end

  property "all properties hold also with data in a different shape with access functions" do
    ordered_sample_list_gen =
      gen all sample_list <-
                list_of(fixed_list([{:timestamp, float()}, {:data, float()}]), min_length: 2) do
        Enum.sort(sample_list, fn a, b ->
          xa = Keyword.fetch(a, :timestamp)
          xb = Keyword.fetch(b, :timestamp)
          xa <= xb
        end)
      end

    sample_to_x_fun = fn sample -> Keyword.fetch!(sample, :timestamp) end
    sample_to_y_fun = fn sample -> Keyword.fetch!(sample, :data) end
    xy_to_sample_fun = fn x, y -> [timestamp: x, data: y] end

    check all sample_list <- ordered_sample_list_gen,
              avg_bucket_size <- float(min: 1.0, max: length(sample_list)) do
      result =
        ExLTTB.Stream.downsample(
          sample_list,
          avg_bucket_size,
          sample_to_x_fun: sample_to_x_fun,
          sample_to_y_fun: sample_to_y_fun,
          xy_to_sample_fun: xy_to_sample_fun
        )
        |> Enum.to_list()

      assert length(result) <=
               min(length(sample_list), 2 + Float.ceil(length(sample_list) / avg_bucket_size))

      assert Enum.all?(result, fn el -> Enum.member?(sample_list, el) end)
      assert List.first(result) == List.first(sample_list)
      assert List.last(result) == List.last(sample_list)
    end
  end
end
