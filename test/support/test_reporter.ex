defmodule Metrics.Test.EchoReporter do
  @moduledoc """
  Simple reporter sending received values to configured owner process
  """

  use Metrics.Reporter

  @impl true
  def init(opts) do
    owner = Keyword.fetch!(opts, :owner)
    {:ok, %{owner: owner}}
  end

  @impl true
  def handle_emit(metric, view, values, ts, state) do
    send(state.owner, {:report, metric, view, values, ts})
    {:noreply, state}
  end
end
