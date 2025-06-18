defmodule Hog.TelemetryEvents do
  @moduledoc """
  This module provides helpers for dealing with the
  telemetry events emitted by the Hog library.
  """

  @memory_threshold_surpassed [:hog, :memory_threshold, :surpassed]

  @doc """
  This event is emitted when a process surpasses the memory threshold.
  """
  def emit_memory_threshold_surpassed_event(process_memory, pid, current_monotonic_time) do
    :telemetry.execute(
      @memory_threshold_surpassed,
      %{process_memory: process_memory},
      %{pid: pid, current_monotonic_time: current_monotonic_time}
    )
  end
end
