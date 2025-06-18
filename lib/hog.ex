defmodule Hog do
  @opts_schema [
    scan_interval: [
      type: {:tuple, [:pos_integer, {:in, [:seconds, :minutes]}]},
      default: {1, :minutes},
      doc: "The interval for how often the running processes are scanned."
    ],
    memory_threshold: [
      type: {:tuple, [:pos_integer, {:in, [:kilobytes, :megabytes, :kibibytes, :mebibytes]}]},
      default: {100, :megabytes},
      doc: "The memory threshold that determines whether a telemetry event is emitted."
    ],
    max_report_frequency: [
      type: {:tuple, [:pos_integer, {:in, [:seconds, :minutes]}]},
      default: {1, :minutes},
      doc:
        "As not to create too many telemetry events about the same process over and over again, you can specify how often a particular process has a telemetry event emitted for it. The check for the process is based on the PID. So if the process crashes and is restarted, it will be reported again since it is running under a new PID."
    ],
    event_handler: [
      type: {:or, [nil, {:fun, 2}]},
      default: &Hog.Logger.default_logger/2,
      doc: "The handler function that is called when a process surpasses the configured memory_threshold"
    ],
    additional_pid_info_fields: [
      type: {:list, :atom},
      default: [],
      doc:
        "The process info fields that are collected on the running process before emitting the telemetry event that memory usage has exceed configure threshold. The fields that are captured by default are: `[:memory, :reductions, :message_queue_len, :current_stacktrace, :registered_name]`. Any additional fields provided will be included in the telemetry event metadata."
    ]
  ]

  @moduledoc """
  This process will routinely scans all of the running processes and emit a telemetry
  event any time a process surpasses a certain memory threshold. The memory threshold
  along with how often Hog scans all of your running processes is configurable. Once
  a memory hungry process is found, a telemetry event is emitted. You can hook into
  this telemetry event your self to deal with the misbehaving process, or you can use
  the provided `Hog.Logger` module log process information. Below is a listing of
  all of the configuration options available to you.

  Supported options:

  #{NimbleOptions.docs(@opts_schema)}

  Coming soon:
  - ETS table scanning
  """

  use GenServer

  alias Hog.TelemetryEvents

  @type option() :: unquote(NimbleOptions.option_typespec(@opts_schema))

  @default_pid_info_fields [:memory, :reductions, :message_queue_len, :current_stacktrace, :registered_name]

  # +-------------------------------------------------------+
  # |                  Public functions                     |
  # +-------------------------------------------------------+

  def start_link(opts) do
    {:ok, validated_opts} = NimbleOptions.validate(opts, @opts_schema)

    GenServer.start_link(__MODULE__, validated_opts)
  end

  # +-------------------------------------------------------+
  # |                 Callback functions                    |
  # +-------------------------------------------------------+

  @impl true
  def init(opts) do
    # If a logger event handler is specified, attach it via telemetry
    if opts[:event_handler] do
      TelemetryEvents.attach_memory_threshold_surpassed_handler(opts[:event_handler])
    end

    # Get the scan interval
    scan_interval =
      case opts[:scan_interval] do
        {num, :minutes} -> :timer.minutes(num)
        {num, :seconds} -> :timer.seconds(num)
      end

    # Get the memory threshold
    memory_threshold =
      case opts[:memory_threshold] do
        {num, :megabytes} -> num * 1_000_000
        {num, :mebibytes} -> num * 1_048_576
        {num, :kilobytes} -> num * 1_000
        {num, :kibibytes} -> num * 1_024
      end

    # Get the max report frequency
    max_report_frequency =
      case opts[:max_report_frequency] do
        {num, :minutes} -> :timer.minutes(num)
        {num, :seconds} -> :timer.seconds(num)
      end

    # Create the initial state of the GenServer
    state = %{
      init_opts: opts,
      scan_interval: scan_interval,
      memory_threshold: memory_threshold,
      max_report_frequency: max_report_frequency,
      process_info_fields: @default_pid_info_fields ++ opts[:additional_pid_info_fields],
      reported_processes: %{}
    }

    {:ok, state, {:continue, :schedule_next_scan}}
  end

  @impl true
  def handle_continue(:schedule_next_scan, state) do
    Process.send_after(self(), :perform_process_scan, state.scan_interval)

    {:noreply, state}
  end

  @impl true
  def handle_info(:perform_process_scan, state) do
    updated_state =
      Map.update!(state, :reported_processes, fn reported_processes ->
        # TODO: Consider using :memsup instead
        Process.list()
        |> Enum.reduce(reported_processes, fn pid, acc ->
          handle_process_scanning(state, pid, acc)
        end)
      end)

    {:noreply, updated_state, {:continue, :schedule_next_scan}}
  end

  # +-------------------------------------------------------+
  # |               Private helper functions                |
  # +-------------------------------------------------------+
  defp handle_process_scanning(state, pid, acc) do
    with process_info when not is_nil(process_info) <- Process.info(pid, state.process_info_fields),
         %{memory: process_memory} = process_info <- Map.new(process_info),
         current_monotonic_time <- System.monotonic_time(:millisecond),
         true <- process_memory > state.memory_threshold,
         true <- within_max_report_frequency?(pid, state.max_report_frequency, current_monotonic_time, acc) do
      TelemetryEvents.emit_memory_threshold_surpassed_event(
        process_memory,
        pid,
        process_info,
        current_monotonic_time
      )

      Map.put(acc, pid, current_monotonic_time)
    else
      _ ->
        acc
    end
  end

  defp within_max_report_frequency?(pid, max_report_frequency, current_monotonic_time, reported_processes) do
    case Map.get(reported_processes, pid) do
      nil ->
        true

      previous_monotonic_time ->
        previous_monotonic_time + max_report_frequency < current_monotonic_time
    end
  end
end
