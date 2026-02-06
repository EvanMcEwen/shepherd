defmodule Shepherd.Metrics.Pipeline do
  @moduledoc """
  Manages the metrics processing pipeline.

  Attaches configured handlers to telemetry events at application startup.
  Each handler receives all ingested metrics and can process them independently.
  """

  require Logger

  @doc """
  Attaches all configured metrics handlers to telemetry.

  Call this during application startup, after the supervision tree is running.
  """
  def attach_handlers do
    handlers = Application.get_env(:shepherd, :metrics_handlers, default_handlers())

    for {handler_id, handler_module} <- handlers do
      :telemetry.attach(
        "shepherd-metrics-#{handler_id}",
        [:shepherd, :metrics, :ingested],
        &__MODULE__.handle_event/4,
        %{handler: handler_module}
      )
    end

    Logger.info("[Metrics.Pipeline] Attached #{length(handlers)} handler(s)")
    :ok
  end

  @doc """
  Detaches all metrics handlers. Useful for testing.
  """
  def detach_handlers do
    handlers = Application.get_env(:shepherd, :metrics_handlers, default_handlers())

    for {handler_id, _handler_module} <- handlers do
      :telemetry.detach("shepherd-metrics-#{handler_id}")
    end

    :ok
  end

  @doc false
  def handle_event([:shepherd, :metrics, :ingested], _measurements, metadata, config) do
    %{device_id: device_id, metrics: metrics} = metadata
    %{handler: handler_module} = config

    handler_module.handle_metrics(device_id, metrics)
  rescue
    e ->
      Logger.error(
        "[Metrics.Pipeline] Handler #{inspect(config.handler)} failed: #{Exception.message(e)}"
      )
  end

  defp default_handlers do
    [{:logger, Shepherd.Metrics.Handlers.Logger}]
  end
end
