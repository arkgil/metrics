defmodule MetricsTest do
  use ExUnit.Case

  @metric [:metrics, :test, :metric]
  @view [:metrics, :test, :metric, :gauge]

  setup do
    start_supervised!({Metrics.Test.EchoReporter, owner: self()})
    :ok
  end

  test "recorded measurements are forwarded by gauge view to reporter" do
    Metrics.add_view(@metric, @view, :gauge)

    measurement = 16.50
    Metrics.record(@metric, measurement)

    assert_receive {:report, @metric, @view, [{:value, ^measurement}], _ts}
  end
end
