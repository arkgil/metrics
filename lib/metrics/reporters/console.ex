defmodule Metrics.Reporters.Console do
  @moduledoc """
  Reporter printing emitted values to the console
  """

  @behaviour Metrics.Reporter

  def handle_emit(_metric, view, values, ts) do
    formatted_date = ts |> NaiveDateTime.to_date() |> Date.to_iso8601()
    formatted_time = ts |> NaiveDateTime.to_time() |> Time.to_iso8601()

    formatted_view =
      view
      |> Enum.map(&to_string/1)
      |> Enum.intersperse(?.)

    formatted_vals =
      values
      |> Enum.map(fn {name, val} -> [to_string(name), ?=, to_string(val)] end)
      |> Enum.intersperse(?\s)

    line = [
      "report ",
      ?[,
      formatted_date,
      ?],
      ?[,
      formatted_time,
      ?],
      ?\s,
      formatted_view,
      ?:,
      ?\s,
      formatted_vals
    ]

    IO.puts(line)
  end
end
