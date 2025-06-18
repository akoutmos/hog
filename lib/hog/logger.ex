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

  def default_logger(%{process_memory: process_memory}, %{pid: pid, process_info: process_info}) do
    process_state =
      try do
        "#{inspect(:sys.get_state(pid), @inspect_opts)}"
      catch
        _, _ -> "Unable to retrieve process state"
      end

    reductions = process_info.reductions
    message_queue_len = process_info.message_queue_len
    current_stacktrace = process_info.current_stacktrace
    registered_name = process_info.registered_name

    current_stacktrace =
      Enum.map_join(current_stacktrace, "\n", fn term ->
        "  #{inspect(term, @inspect_opts)}"
      end)

    registered_name =
      case registered_name do
        [] -> "Not a named process"
        name -> " #{inspect(name, @inspect_opts)}"
      end

    Logger.warning("""
    ================ Hog memory threshold warning  ================
    PID: #{inspect(pid, @inspect_opts)}
    Process name: #{registered_name}
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
