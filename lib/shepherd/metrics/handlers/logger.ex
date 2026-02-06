defmodule Shepherd.Metrics.Handlers.Logger do
  @moduledoc """
  Simple logging handler for metrics.

  Logs each batch of metrics at debug level. Useful for development
  and debugging. Not recommended for production at high volume.
  """

  @behaviour Shepherd.Metrics.Handler

  require Logger

  @impl true
  def handle_metrics(device_id, metrics) do
    metric_summary =
      metrics
      |> Enum.map(fn m ->
        unit = if m.unit, do: " #{m.unit}", else: ""
        "#{m.name}=#{m.value}#{unit}"
      end)
      |> Enum.join(", ")

    Logger.debug("[Metrics] Device #{device_id}: #{metric_summary}")
    :ok
  end
end
