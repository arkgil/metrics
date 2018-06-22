defmodule Metrics.ProbeSupervisor do
  @moduledoc false

  use DynamicSupervisor

  @spec child_spec(any) :: Supervisor.child_spec()
  def child_spec(_) do
    opts = [name: __MODULE__, strategy: :one_for_one]

    %{
      id: __MODULE__,
      start: {DynamicSupervisor, :start_link, [opts]}
    }
  end

  @spec start_child(Supervisor.child_spec() | module | {module, term}) ::
          DynamicSupervisor.on_start_child()
  def start_child(child_spec) do
    DynamicSupervisor.start_child(__MODULE__, child_spec)
  end
end
