defmodule Hog.Logger do
  @moduledoc """
  This module provides default loggers for when memory threshold
  warnings are emitted by Hog.
  """

  require Logger

  def default_logger(%{process_memory: process_memory}, %{pid: pid}) do
    Logger.warning("""
    PID: #{inspect(pid)}
    Process memory: #{inspect(process_memory)}
    """)
  end
end
