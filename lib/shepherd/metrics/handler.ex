defmodule Shepherd.Metrics.Handler do
  @moduledoc """
  Behaviour for metrics handlers.

  Handlers receive validated metric batches and process them
  as needed: log, store, cache, forward to external services, etc.

  Handlers are called synchronously from the emitting process
  (the DeviceChannel). If a handler needs to do slow work, it
  should delegate to a GenServer or Task.
  """

  @type metric :: %{
          name: String.t(),
          value: float(),
          unit: String.t() | nil,
          recorded_at: DateTime.t()
        }

  @doc """
  Called when metrics are ingested from a device.

  Should return `:ok`. Exceptions are caught and logged by the pipeline.
  """
  @callback handle_metrics(device_id :: pos_integer(), metrics :: [metric]) :: :ok
end
