defmodule Metrics.Gauge do
  @moduledoc false

  use GenServer

  alias Metrics.{ViewStore, ReporterStore}

  @spec child_spec(any) :: Supervisor.child_spec()
  def child_spec(_) do
    %{
      id: __MODULE__,
      start: {GenServer, :start_link, [__MODULE__, [], [name: __MODULE__]]}
    }
  end

  @spec handle_measurement(Metrics.metric(), Metrics.view(), pid, Metrics.measurement()) :: :ok
  def handle_measurement(metric, view, _, measurement) do
    ## should we send keyword list of aggregated values or maybe a struct?
    ## structs can be documented nicely but on the other hand reporters would need to know how
    ## handle them
    ReporterStore.dispatch(metric, view, [{:value, measurement}])
  end

  @spec register(Metrics.metric(), Metrics.view()) :: :ok | {:error, :already_exists}
  def register(metric, view) do
    GenServer.call(__MODULE__, {:register, metric, view})
  end

  @impl true
  def init(_) do
    {:ok, []}
  end

  @impl true
  def handle_call({:register, metric, view}, _, state) do
    reply = ViewStore.register(metric, view, __MODULE__)
    {:reply, reply, state}
  end
end
