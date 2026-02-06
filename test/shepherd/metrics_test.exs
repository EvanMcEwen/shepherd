defmodule Shepherd.MetricsTest do
  use ExUnit.Case, async: true

  alias Shepherd.Metrics

  setup do
    # Capture telemetry events
    test_pid = self()

    :telemetry.attach(
      "test-metrics-handler",
      [:shepherd, :metrics, :ingested],
      fn event, measurements, metadata, _config ->
        send(test_pid, {:telemetry_event, event, measurements, metadata})
      end,
      nil
    )

    on_exit(fn ->
      :telemetry.detach("test-metrics-handler")
    end)

    {:ok, device_id: 123}
  end

  describe "ingest/2" do
    test "emits telemetry with valid metrics", %{device_id: device_id} do
      metrics = [
        %{name: "cpu_temp", value: 45.5, unit: "celsius", recorded_at: DateTime.utc_now()},
        %{name: "memory_percent", value: 62.3, unit: "percent", recorded_at: DateTime.utc_now()}
      ]

      assert {:ok, 2} = Metrics.ingest(device_id, metrics)

      assert_receive {:telemetry_event, [:shepherd, :metrics, :ingested], %{count: 2}, metadata}
      assert metadata.device_id == device_id
      assert length(metadata.metrics) == 2
    end

    test "accepts string keys", %{device_id: device_id} do
      metrics = [
        %{"name" => "cpu_temp", "value" => 45.5, "recorded_at" => DateTime.utc_now()}
      ]

      assert {:ok, 1} = Metrics.ingest(device_id, metrics)
      assert_receive {:telemetry_event, _, _, _}
    end

    test "accepts integer timestamps", %{device_id: device_id} do
      metrics = [
        %{name: "cpu_temp", value: 45.5, recorded_at: System.system_time(:second)}
      ]

      assert {:ok, 1} = Metrics.ingest(device_id, metrics)
      assert_receive {:telemetry_event, _, _, _}
    end

    test "accepts ISO8601 timestamps", %{device_id: device_id} do
      metrics = [
        %{name: "cpu_temp", value: 45.5, recorded_at: DateTime.to_iso8601(DateTime.utc_now())}
      ]

      assert {:ok, 1} = Metrics.ingest(device_id, metrics)
      assert_receive {:telemetry_event, _, _, _}
    end

    test "converts integer values to float", %{device_id: device_id} do
      metrics = [
        %{name: "count", value: 42, recorded_at: DateTime.utc_now()}
      ]

      assert {:ok, 1} = Metrics.ingest(device_id, metrics)

      assert_receive {:telemetry_event, _, _, metadata}
      [metric] = metadata.metrics
      assert metric.value == 42.0
      assert is_float(metric.value)
    end

    test "rejects metrics with timestamps too far in future", %{device_id: device_id} do
      future = DateTime.add(DateTime.utc_now(), 120, :second)

      metrics = [
        %{name: "cpu_temp", value: 45.5, recorded_at: future}
      ]

      assert {:ok, 0} = Metrics.ingest(device_id, metrics)
      refute_receive {:telemetry_event, _, _, _}
    end

    test "filters out metrics with missing name", %{device_id: device_id} do
      metrics = [
        %{value: 45.5, recorded_at: DateTime.utc_now()},
        %{name: "valid", value: 1.0, recorded_at: DateTime.utc_now()}
      ]

      assert {:ok, 1} = Metrics.ingest(device_id, metrics)

      assert_receive {:telemetry_event, _, %{count: 1}, metadata}
      assert length(metadata.metrics) == 1
      assert hd(metadata.metrics).name == "valid"
    end

    test "filters out metrics with missing value", %{device_id: device_id} do
      metrics = [
        %{name: "cpu_temp", recorded_at: DateTime.utc_now()},
        %{name: "valid", value: 1.0, recorded_at: DateTime.utc_now()}
      ]

      assert {:ok, 1} = Metrics.ingest(device_id, metrics)
    end

    test "filters out metrics with missing timestamp", %{device_id: device_id} do
      metrics = [
        %{name: "cpu_temp", value: 45.5},
        %{name: "valid", value: 1.0, recorded_at: DateTime.utc_now()}
      ]

      assert {:ok, 1} = Metrics.ingest(device_id, metrics)
    end

    test "handles empty list without emitting telemetry", %{device_id: device_id} do
      assert {:ok, 0} = Metrics.ingest(device_id, [])
      refute_receive {:telemetry_event, _, _, _}
    end

    test "handles all invalid metrics without emitting telemetry", %{device_id: device_id} do
      metrics = [
        %{name: "no_value", recorded_at: DateTime.utc_now()},
        %{value: 1.0, recorded_at: DateTime.utc_now()}
      ]

      assert {:ok, 0} = Metrics.ingest(device_id, metrics)
      refute_receive {:telemetry_event, _, _, _}
    end

    test "preserves unit when provided", %{device_id: device_id} do
      metrics = [
        %{name: "temp", value: 45.5, unit: "celsius", recorded_at: DateTime.utc_now()}
      ]

      assert {:ok, 1} = Metrics.ingest(device_id, metrics)

      assert_receive {:telemetry_event, _, _, metadata}
      assert hd(metadata.metrics).unit == "celsius"
    end

    test "unit is nil when not provided", %{device_id: device_id} do
      metrics = [
        %{name: "count", value: 42, recorded_at: DateTime.utc_now()}
      ]

      assert {:ok, 1} = Metrics.ingest(device_id, metrics)

      assert_receive {:telemetry_event, _, _, metadata}
      assert hd(metadata.metrics).unit == nil
    end
  end
end
