defmodule Metrics.ReporterStore do
  @moduledoc false

  use GenServer

  alias Metrics.{FastTables, Reporter}

  @typep fast_table_entry :: {:reporter, pid}

  @spec child_spec(any) :: Supervisor.child_spec()
  def child_spec(_) do
    %{
      id: __MODULE__,
      start: {GenServer, :start_link, [__MODULE__, [], [name: __MODULE__]]},
      type: :worker
    }
  end

  @spec register() :: :ok | {:error, :already_registered}
  def register() do
    GenServer.call(__MODULE__, {:register, self()})
  end

  @spec dispatch(Metrics.metric(), Metrics.view(), [Metrics.value()]) :: :ok
  def dispatch(metric, view, values) do
    timestamp = NaiveDateTime.utc_now()

    for {:reporter, pid} <- get_reporters() do
      Reporter.notify(pid, metric, view, values, timestamp)
    end
  end

  @spec get_reporters() :: [fast_table_entry]
  defp get_reporters() do
    :ets.lookup(FastTables.get(), :reporter)
  end

  @impl true
  def init(_) do
    {:ok, %{monitors: %{}, reporters: MapSet.new()}}
  end

  @impl true
  def handle_call({:register, pid}, _, state) do
    if MapSet.member?(state.reporters, pid) do
      {:reply, {:error, :already_registered}, state}
    else
      reporters = MapSet.put(state.reporters, pid)
      ref = Process.monitor(pid)
      monitors = Map.put(state.monitors, pid, ref)
      add_fast_tables_entry(pid)
      new_state = %{state | reporters: reporters, monitors: monitors}
      {:reply, :ok, new_state}
    end
  end

  @impl true
  def handle_info({:DOWN, ref, :process, pid, _}, state) do
    ^ref = Map.get(state.monitors, pid)
    remove_fast_tables_entry(pid)
    monitors = Map.delete(state.monitors, pid)
    reporters = MapSet.delete(state.reporters, pid)
    new_state = %{state | reporters: reporters, monitors: monitors}
    {:noreply, new_state}
  end

  @spec add_fast_tables_entry(pid) :: any
  defp add_fast_tables_entry(pid) do
    entry = {:reporter, pid}

    for table <- FastTables.get_all() do
      :ets.insert(table, entry)
    end
  end

  @spec remove_fast_tables_entry(pid) :: any
  defp remove_fast_tables_entry(pid) do
    for table <- FastTables.get_all() do
      :ets.delete_object(table, {:reporter, pid})
    end
  end
end
