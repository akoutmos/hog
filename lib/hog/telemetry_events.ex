defmodule Hog.TelemetryEvents do
  @moduledoc """
  This module provides helpers for dealing with the
  telemetry events emitted by the Hog library.
  """

  @memory_threshold_surpassed [:hog, :memory_threshold, :surpassed]

  @doc """
  This event is emitted when a process surpasses the memory threshold. It contains the following
  measurements and metadata:

   #### Measurements

  * `:process_memory` — the amount of memory consumed by the process (in bytes)

  #### Metadata

  * `:pid` — the PID of the offending process
  * `:current_monotonic_time` — the monotonic time when the exceeded memory threshold was detected
  * `:timestamp` - the timestamp when the exceeded memory threshold was detected
  """
  def emit_memory_threshold_surpassed_event(process_memory, pid, current_monotonic_time) do
    :telemetry.execute(
      @memory_threshold_surpassed,
      %{process_memory: process_memory},
      %{pid: pid, current_monotonic_time: current_monotonic_time, timestamp: NaiveDateTime.utc_now()}
    )
  end

  def attach_memory_threshold_surpassed_handler(handler_function) do
    :ok =
      :telemetry.attach(
        "hog_memory_threshold_surpassed_handler",
        @memory_threshold_surpassed,
        &__MODULE__.handler_wrapper/4,
        handler_function
      )
  end

  @doc false
  def handler_wrapper(_event, measurements, metadata, handler_function) do
    handler_function.(measurements, metadata)
  end
end
