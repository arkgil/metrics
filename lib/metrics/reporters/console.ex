defmodule Metrics.Reporters.Console do
  @moduledoc """
  Reporter printing emitted values to the console
  """

  @behaviour Metrics.Reporter

  def handle_emit(_metric, view, values, timestamp) do
    formatted_ts = NaiveDateTime.to_iso8601(timestamp)

    formatted_view =
      view
      |> Enum.map(&to_string/1)
      |> Enum.intersperse(?.)

    formatted_vals =
      values
      |> Enum.map(fn {name, val} -> [to_string(name), ?=, to_string(val)] end)
      |> Enum.intersperse(?\s)

    line = [?[, formatted_ts, ?], ?\s, formatted_view, ?:, ?\s, formatted_vals]
    IO.puts(line)
  end
end
