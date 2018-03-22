defmodule ExLTTBTest do
  use ExUnit.Case
  use ExUnitProperties
  doctest ExLTTB

  property "resulting list has always length <= threshold" do
    greater_than_one_gen = gen all int <- positive_integer(), do: int + 1
    ordered_sample_list_gen =
      gen all sample_list <- list_of(fixed_map(%{x: float(), y: float()}), min_length: 2) do
        Enum.sort(sample_list, fn %{x: xa}, %{x: xb} -> xa <= xb end)
      end

    check all sample_list <- ordered_sample_list_gen,
              threshold <- greater_than_one_gen do
      result = ExLTTB.downsample_to(sample_list, threshold)
      assert length(result) == threshold || length(sample_list) <= threshold
    end
  end

  property "the samples in the result are contained in the original list (including additional fields)" do
    greater_than_one_gen = gen all int <- positive_integer(), do: int + 1
    ordered_sample_list_gen =
      gen all sample_list <-
                list_of(fixed_map(%{x: float(), y: float(), other: float()}), min_length: 2) do
        Enum.sort(sample_list, fn %{x: xa}, %{x: xb} -> xa <= xb end)
      end

    check all sample_list <- ordered_sample_list_gen,
              threshold <- greater_than_one_gen do
      result = ExLTTB.downsample_to(sample_list, threshold)
      assert Enum.all?(result, fn el -> Enum.member?(sample_list, el) end)
    end
  end

  property "the first and last sample are the same of the original list" do
    greater_than_one_gen = gen all int <- positive_integer(), do: int + 1
    ordered_sample_list_gen =
      gen all sample_list <- list_of(fixed_map(%{x: float(), y: float()}), min_length: 2) do
        Enum.sort(sample_list, fn %{x: xa}, %{x: xb} -> xa <= xb end)
      end

    check all sample_list <- ordered_sample_list_gen,
              threshold <- greater_than_one_gen do
      result = ExLTTB.downsample_to(sample_list, threshold)
      assert List.first(result) == List.first(sample_list)
      assert List.last(result) == List.last(sample_list)
    end
  end

  property "resulting list has the same length if threshold >= original list length" do
    ordered_sample_list_gen =
      gen all sample_list <- list_of(fixed_map(%{x: float(), y: float()}), min_length: 2) do
        Enum.sort(sample_list, fn %{x: xa}, %{x: xb} -> xa <= xb end)
      end

    check all sample_list <- ordered_sample_list_gen,
              threshold_offset <- positive_integer() do
      threshold = length(sample_list) + threshold_offset
      result = ExLTTB.downsample_to(sample_list, threshold)
      assert length(result) == length(sample_list)
    end
  end

  property "returns just the first sample if threshold == 1" do
    ordered_sample_list_gen =
      gen all sample_list <- list_of(fixed_map(%{x: float(), y: float()}), min_length: 1) do
        Enum.sort(sample_list, fn %{x: xa}, %{x: xb} -> xa <= xb end)
      end

    check all sample_list <- ordered_sample_list_gen do
      assert Enum.take(sample_list, 1) == ExLTTB.downsample_to(sample_list, 1)
    end
  end

  property "returns an empty list if threshold == 0" do
    ordered_sample_list_gen =
      gen all sample_list <- list_of(fixed_map(%{x: float(), y: float()}), min_length: 0) do
        Enum.sort(sample_list, fn %{x: xa}, %{x: xb} -> xa <= xb end)
      end

    check all sample_list <- ordered_sample_list_gen do
      assert [] == ExLTTB.downsample_to(sample_list, 0)
    end
  end

  property "returns the same sample_list if 0 <= length(sample_list) <= 2" do
    greater_than_two_gen = gen all int <- positive_integer(), do: int + 1

    ordered_sample_list_gen =
      gen all sample_list <- list_of(fixed_map(%{x: float(), y: float()}), max_length: 2) do
        Enum.sort(sample_list, fn %{x: xa}, %{x: xb} -> xa <= xb end)
      end

    check all sample_list <- ordered_sample_list_gen,
              threshold <- greater_than_two_gen do
      assert sample_list == ExLTTB.downsample_to(sample_list, threshold)
    end
  end

  property "all properties hold also with data in a different shape with access functions" do
    greater_than_one_gen = gen all int <- positive_integer(), do: int + 1
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
              threshold <- greater_than_one_gen do
      result =
        ExLTTB.downsample_to(
          sample_list,
          threshold,
          sample_to_x_fun: sample_to_x_fun,
          sample_to_y_fun: sample_to_y_fun,
          xy_to_sample_fun: xy_to_sample_fun
        )

      assert length(result) == threshold || length(sample_list) <= threshold
      assert Enum.all?(result, fn el -> Enum.member?(sample_list, el) end)
      assert List.first(result) == List.first(sample_list)
      assert List.last(result) == List.last(sample_list)
    end
  end
end
