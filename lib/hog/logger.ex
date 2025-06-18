defmodule Hog.Logger do
  @moduledoc """
  This module provides default loggers for when memory threshold
  warnings are emitted by Hog.
  """

  require Logger

  @inspect_opts [
    limit: :infinity,
    printable_limit: :infinity,
    pretty: true,
    width: 120
  ]

  def default_logger(%{process_memory: process_memory}, %{pid: pid}) do
    process_state =
      try do
        "#{inspect(:sys.get_state(pid), @inspect_opts)}"
      catch
        _, _ -> "Unable to retrieve process state"
      end

    {:reductions, reductions} = Process.info(pid, :reductions)
    {:message_queue_len, message_queue_len} = Process.info(pid, :message_queue_len)
    {:current_stacktrace, current_stacktrace} = Process.info(pid, :current_stacktrace)

    current_stacktrace =
      Enum.map_join(current_stacktrace, "\n", fn term ->
        "  #{inspect(term, @inspect_opts)}"
      end)

    Logger.warning("""
    ================ Hog memory threshold warning  ================
    PID: #{inspect(pid, @inspect_opts)}
    Process memory: #{pretty_print_number(process_memory)} bytes
    Reductions: #{pretty_print_number(reductions)}
    Message queue length: #{pretty_print_number(message_queue_len)}
    Current stacktrace:
    #{current_stacktrace}
    Process state: #{process_state}
    """)
  end

  defp pretty_print_number(number) do
    number
    |> Integer.to_string()
    |> to_charlist()
    |> Enum.reverse()
    |> Enum.chunk_every(3)
    |> Enum.map(&Enum.reverse(&1))
    |> Enum.reverse()
    |> Enum.join(",")
  end
end
