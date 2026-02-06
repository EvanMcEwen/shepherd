defmodule Shepherd.Metrics do
  @moduledoc """
  Context for device metrics ingestion.

  Validates incoming metrics and emits telemetry events for handlers.
  Does not store metrics directly - that's the responsibility of handlers.
  """

  @max_clock_drift_seconds 60

  @type raw_metric :: %{
          optional(:name) => String.t(),
          optional(:value) => number(),
          optional(:unit) => String.t(),
          optional(:recorded_at) => DateTime.t() | integer() | String.t()
        }

  @type metric :: %{
          name: String.t(),
          value: float(),
          unit: String.t() | nil,
          recorded_at: DateTime.t()
        }

  @doc """
  Ingests a batch of metrics from a device.

  Validates and normalizes metrics, then emits a telemetry event
  for handlers to process.

  Returns `{:ok, count}` where count is the number of valid metrics.
  """
  @spec ingest(pos_integer(), [raw_metric()]) :: {:ok, non_neg_integer()}
  def ingest(device_id, metrics) when is_list(metrics) do
    now = DateTime.utc_now()

    validated =
      metrics
      |> Enum.map(&normalize_metric/1)
      |> Enum.filter(&valid_metric?(&1, now))

    if validated != [] do
      :telemetry.execute(
        [:shepherd, :metrics, :ingested],
        %{count: length(validated)},
        %{device_id: device_id, metrics: validated}
      )
    end

    {:ok, length(validated)}
  end

  defp normalize_metric(m) do
    %{
      name: get_string(m, :name),
      value: get_float(m, :value),
      unit: get_string(m, :unit),
      recorded_at: get_timestamp(m, :recorded_at)
    }
  end

  defp valid_metric?(%{name: nil}, _now), do: false
  defp valid_metric?(%{value: nil}, _now), do: false
  defp valid_metric?(%{recorded_at: nil}, _now), do: false

  defp valid_metric?(%{recorded_at: ts}, now) do
    DateTime.diff(ts, now, :second) <= @max_clock_drift_seconds
  end

  defp get_string(map, key) do
    value = Map.get(map, key) || Map.get(map, to_string(key))
    if is_binary(value), do: value, else: nil
  end

  defp get_float(map, key) do
    value = Map.get(map, key) || Map.get(map, to_string(key))

    case value do
      v when is_float(v) -> v
      v when is_integer(v) -> v * 1.0
      _ -> nil
    end
  end

  defp get_timestamp(map, key) do
    value = Map.get(map, key) || Map.get(map, to_string(key))
    parse_timestamp(value)
  end

  defp parse_timestamp(%DateTime{} = dt), do: dt

  defp parse_timestamp(ts) when is_integer(ts) do
    case DateTime.from_unix(ts, :second) do
      {:ok, dt} -> dt
      _ -> nil
    end
  end

  defp parse_timestamp(ts) when is_binary(ts) do
    case DateTime.from_iso8601(ts) do
      {:ok, dt, _} -> dt
      _ -> nil
    end
  end

  defp parse_timestamp(_), do: nil
end
