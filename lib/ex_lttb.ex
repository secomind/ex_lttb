defmodule ExLTTB do
  @moduledoc """
  Documentation for ExLTTB.
  """

  def lttb(_sample_list, threshold) when threshold < 2 do
    {:error, :invalid_threshold}
  end

  def lttb(sample_list, threshold) when threshold > length(sample_list) do
    {:ok, sample_list}
  end
end
