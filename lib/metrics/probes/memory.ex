defmodule Metrics.Probes.Memory do
  @moduledoc """
  Probe reporting memory usage periodically

  It records the following metrics:
  * `[:core, :memory, :allocated, :total]` - total amount of memory allocated
  * `[:core, :memory, :allocated, :system]` - total amount of memory allocated minus the memory
    allocated for processes
  * `[:core, :memory, :allocated, :processes]` - total amount of memory allocated for processes
  * `[:core, :memory, :allocated, :atoms]` - total amount of memory allocated for atoms
  * `[:core, :memory, :allocated, :binaries]` - total amount of memory allocated for binaries
  * `[:core, :memory, :allocated, :ets]` - total amount of memory allocated for ETS tables
  * `[:core, :memory, :used, :atoms]` - total amount of memory used by atoms
  * `[:core, :memory, :used, :processes]` - total amount of memory user by processes

  Each metric's unit is bytes.

  This probe also automatically adds a gauge view for each of these metrics with the same name
  as the metric itself.
  """

  use GenServer

  alias Metrics.ProbeSupervisor

  @type interval :: pos_integer
  @type option :: {:interval, interval}
  @type options :: [option]

  @default_interval 10_000

  @doc """
  Starts the memory probe

  Allowed options:
  * `:interval` - how often the memory metrics should be recorded. The unit is millisecond.
  """
  @spec start(options) :: Supervisor.on_start_child()
  def start(opts \\ []) do
    ProbeSupervisor.start_child(child_spec(opts))
  end

  @spec child_spec(options) :: Supervisor.child_spec()
  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]}
    }
  end

  @doc false
  @spec start_link(options) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(opts) do
    interval = opts[:interval] || @default_interval
    add_views()
    set_timer(interval)
    {:ok, %{interval: interval}}
  end

  @impl true
  def handle_info(:record, state) do
    record_metrics()
    set_timer(state.interval)
    {:noreply, state}
  end

  @spec set_timer(interval) :: :ok
  defp set_timer(interval) do
    Process.send_after(self(), :record, interval)
  end

  defp add_views() do
    metrics = [
      prefix_allocated(:total),
      prefix_allocated(:system),
      prefix_allocated(:processes),
      prefix_allocated(:atoms),
      prefix_allocated(:binaries),
      prefix_allocated(:ets),
      prefix_used(:atoms),
      prefix_used(:processes)
    ]

    for metric <- metrics do
      Metrics.add_view(metric, metric, :gauge)
    end
  end

  defp record_metrics() do
    memory_info = :erlang.memory()
    Enum.each(memory_info, &record_metric/1)
  end

  @spec record_metric({:erlang.memory_type(), bytes :: non_neg_integer()}) :: :ok
  defp record_metric({memory_type, size}) do
    metric = metric_for_memory_type(memory_type)
    if metric, do: Metrics.record(metric, size)
  end

  @spec metric_for_memory_type(:erlang.memory_type()) :: Metrics.metric()
  defp metric_for_memory_type(:total), do: prefix_allocated(:total)
  defp metric_for_memory_type(:system), do: prefix_allocated(:system)
  defp metric_for_memory_type(:processes), do: prefix_allocated(:processes)
  defp metric_for_memory_type(:atom), do: prefix_allocated(:atoms)
  defp metric_for_memory_type(:binary), do: prefix_allocated(:binaries)
  defp metric_for_memory_type(:ets), do: prefix_allocated(:ets)
  defp metric_for_memory_type(:atom_used), do: prefix_used(:atoms)
  defp metric_for_memory_type(:processes_used), do: prefix_used(:processes)
  defp metric_for_memory_type(_), do: nil

  @spec prefix_allocated(atom()) :: Metrics.metric()
  defp prefix_allocated(suffix), do: [:core, :memory, :allocated, suffix]

  @spec prefix_used(atom()) :: Metrics.metric()
  defp prefix_used(suffix), do: [:core, :memory, :used, suffix]
end
