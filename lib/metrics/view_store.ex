defmodule Metrics.ViewStore do
  @moduledoc false
  ## GenServer managing views. All additions and removals of views go through this process to
  ## guarantee atomicity of these operations through all fast tables.
  ##
  ## Miscellanous info like view description could be stored in a single table, since access to it
  ## doesn't lie on the critical path.

  use GenServer

  alias Metrics.FastTables

  @typep fast_table_entry :: {{:view, Metrics.metric()}, Metrics.view(), module(), pid()}
  @typep monitors :: %{pid => {reference, [Metrics.view()]}}

  @spec child_spec(any) :: Supervisor.child_spec()
  def child_spec(_) do
    %{
      id: __MODULE__,
      start: {GenServer, :start_link, [__MODULE__, [], [name: __MODULE__]]},
      type: :worker
    }
  end

  @spec register(Metrics.metric(), Metrics.view(), module()) :: :ok | {:error, :already_exists}
  def register(metric, view, view_module) do
    GenServer.call(__MODULE__, {:register, metric, view, view_module, self()})
  end

  @spec dispatch(Metrics.metric(), Metrics.measurement()) :: :ok
  def dispatch(metric, measurement) do
    for {{:view, ^metric}, view, view_module, view_pid} <- get_views(metric) do
      view_module.handle_measurement(metric, view, view_pid, measurement)
    end

    :ok
  end

  @spec get_views(Metrics.metric()) :: [fast_table_entry()]
  defp get_views(metric) do
    :ets.lookup(FastTables.get(), {:view, metric})
  end

  @impl true
  def init(_) do
    {:ok, %{monitors: %{}, views: MapSet.new()}}
  end

  @impl true
  def handle_call({:register, metric, view, view_module, view_pid}, _, state) do
    if MapSet.member?(state.views, view) do
      {:reply, {:error, :already_exists}, state}
    else
      views = MapSet.put(state.views, view)
      monitors = maybe_monitor(state.monitors, view_pid, view)
      add_fast_tables_entry(metric, view, view_module, view_pid)
      new_state = %{state | views: views, monitors: monitors}
      {:reply, :ok, new_state}
    end
  end

  @impl true
  def handle_info({:DOWN, ref, :process, pid, _}, state) do
    {^ref, views} = Map.get(state.monitors, pid)
    remove_fast_tables_entries(views)
    monitors = Map.delete(state.monitors, pid)
    views = Enum.reduce(views, state.views, fn view, views -> MapSet.delete(views, view) end)
    new_state = %{state | views: views, monitors: monitors}
    {:noreply, new_state}
  end

  @spec maybe_monitor(monitors, pid, Metrics.view()) :: monitors
  defp maybe_monitor(monitors, pid, view) do
    case Map.fetch(monitors, pid) do
      {:ok, {ref, views}} ->
        Map.put(monitors, pid, {ref, [view | views]})

      :error ->
        ref = Process.monitor(pid)
        Map.put(monitors, pid, {ref, [view]})
    end
  end

  @spec add_fast_tables_entry(Metrics.metric(), Metrics.view(), module(), pid) :: any
  defp add_fast_tables_entry(metric, view, view_module, pid) do
    entry = {{:view, metric}, view, view_module, pid}

    for table <- FastTables.get_all() do
      :ets.insert(table, entry)
    end
  end

  @spec remove_fast_tables_entries([Metrics.view()]) :: any
  defp remove_fast_tables_entries(views), do: Enum.each(views, &remove_fast_tables_entry/1)

  @spec remove_fast_tables_entry(Metrics.view()) :: any
  defp remove_fast_tables_entry(view) do
    pattern = {{:view, :_}, view, :_, :_}

    for table <- FastTables.get_all() do
      [entry] = :ets.match_object(table, pattern)
      :ets.delete_object(table, entry)
    end
  end
end
