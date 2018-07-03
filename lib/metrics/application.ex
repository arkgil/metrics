defmodule Metrics.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      Metrics.FastTables,
      Metrics.ViewStore,
      Metrics.Gauge,
      Metrics.ProbeSupervisor,
      Metrics.ReporterStore,
      Metrics.ReporterSupervisor
    ]

    opts = [strategy: :one_for_one, name: Metrics.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
