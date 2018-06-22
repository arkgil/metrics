defmodule Metrics.Reporter do
  @moduledoc """
  Behaviour for reporters forwarding values emitted by views to external systems

  Currently there is no way to subscribe reporter only to specific metrics or views.
  """

  use GenServer

  alias Metrics.ReporterSupervisor

  @doc """
  Called whenever any of the views emits its values

  The last argument is the UTC timestamp when the values have been emitted.
  """
  @callback handle_emit(Metrics.metric(), Metrics.view(), [Metrics.value()], NaiveDateTime.t()) ::
              any

  @doc """
  Returns a child spec of the reporter

  `args` is a list of arguments as you would pass to `start_link/2`.
  """
  @spec child_spec(list) :: Supervisor.child_spec()
  def child_spec(args) when is_list(args) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, args}
    }
  end

  @doc """
  Starts a given reporter and links to the calling process
  """
  @spec start_link(Metrics.reporter()) :: GenServer.on_start()
  def start_link(reporter) do
    GenServer.start_link(__MODULE__, [reporter], [])
  end

  @doc """
  Starts a given reporter under Metric's supervision tree
  """
  @spec start(Metrics.reporter()) :: Supervisor.on_start_child()
  def start(reporter) do
    ReporterSupervisor.start_child([reporter])
  end

  @doc false
  @spec notify(pid, Metris.metric(), Metrics.view(), [Metrics.value()], NaiveDateTime.t()) :: :ok
  def notify(pid, metric, view, values, timestamp) do
    GenServer.cast(pid, {:emitted, metrics, view, values, timestamp})
  end

  @impl true
  def init([reporter]) do
    {:ok, %{reporter: reporter}}
  end

  @impl true
  def handle_cast({:emitted, metric, view, values, timestamp}, state) do
    state.reporter.handle_emit(metric, view, values, timestamp)
    {:noreply, state}
  end
end
