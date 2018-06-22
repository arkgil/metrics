defmodule Metrics.ReporterSupervisor do
  @moduledoc false

  use Supervisor

  alias Metrics.Reporter

  @spec child_spec(any) :: Supervisor.child_spec()
  def child_spec(_) do
    %{
      id: __MODULE__,
      start: {Supervisor, :start_link, [__MODULE__, [], [name: __MODULE__]]}
    }
  end

  @spec start_child(list) :: Supervisor.on_start_child()
  def start_child(args) when is_list(args) do
    Supervisor.start_child(__MODULE__, args)
  end

  @impl true
  def init(_) do
    children = [
      {Reporter, []}
    ]

    Supervisor.init(children, strategy: :simple_one_for_one)
  end
end
