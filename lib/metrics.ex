defmodule Metrics do
  @moduledoc """
  Application for gathering, aggregating and reporting metrics.
  """

  alias Metrics.ViewStore

  @type metric :: [atom | String.t() | number]
  @type measurement :: number
  @type view :: [atom | String.t() | number]

  @doc """
  Records a single measurement of a metric

  Raises an error if given metric doesn't exist.
  """
  @spec record(metric, measurement) :: :ok
  def record(metric, measurement) when is_list(metric) and is_number(measurement) do
    ViewStore.dispatch(metric, measurement)
  end
end
