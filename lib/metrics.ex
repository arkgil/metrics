defmodule Metrics do
  @moduledoc """
  Application for gathering, aggregating and reporting metrics.
  """

  alias Metrics.{ViewStore, Gauge, Reporter}

  @type metric :: [atom | String.t() | number]
  @type measurement :: number
  @type view :: [atom | String.t() | number]
  @type view_type :: :gauge
  @type value :: {atom, number}
  @type reporter :: module
  @type timestamp :: NaiveDateTime.t()

  @doc """
  Records a single measurement of a metric
  """
  @spec record(metric, measurement) :: :ok
  def record(metric, measurement) when is_list(metric) and is_number(measurement) do
    ViewStore.dispatch(metric, measurement)
  end

  @doc """
  Adds a new view of the given metric
  """
  @spec add_view(metric, view, view_type) :: :ok | {:error, :already_exists}
  def add_view(metric, view, :gauge) do
    Gauge.register(metric, view)
  end

  @doc """
  Adds a new reporter susbcribed to all the metrics
  """
  @spec add_reporter(reporter, arg :: term(), GenServer.options()) :: Supervisor.on_start_child()
  def add_reporter(reporter, arg, opts \\ []) do
    Reporter.start(reporter, arg, opts)
  end
end
