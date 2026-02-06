defmodule Shepherd.Metrics.PipelineTest do
  use ExUnit.Case

  alias Shepherd.Metrics.Pipeline

  defmodule TestHandler do
    @behaviour Shepherd.Metrics.Handler

    def handle_metrics(device_id, metrics) do
      send(:pipeline_test, {:handled, device_id, metrics})
      :ok
    end
  end

  defmodule FailingHandler do
    @behaviour Shepherd.Metrics.Handler

    def handle_metrics(_device_id, _metrics) do
      raise "intentional failure"
    end
  end

  setup do
    Process.register(self(), :pipeline_test)

    # Clean up any existing handlers
    try do
      :telemetry.detach("test-handler")
    rescue
      _ -> :ok
    end

    try do
      :telemetry.detach("test-failing-handler")
    rescue
      _ -> :ok
    end

    :ok
  end

  describe "attach_handlers/0" do
    test "attaches configured handlers" do
      Application.put_env(:shepherd, :metrics_handlers, [{:test, TestHandler}])

      on_exit(fn ->
        Application.delete_env(:shepherd, :metrics_handlers)

        try do
          :telemetry.detach("shepherd-metrics-test")
        rescue
          _ -> :ok
        end
      end)

      assert :ok = Pipeline.attach_handlers()

      # Emit event and verify handler receives it
      :telemetry.execute(
        [:shepherd, :metrics, :ingested],
        %{count: 1},
        %{device_id: 1, metrics: [%{name: "test", value: 1.0, unit: nil, recorded_at: DateTime.utc_now()}]}
      )

      assert_receive {:handled, 1, metrics}
      assert [metric] = metrics
      assert metric.name == "test"
      assert metric.value == 1.0
    end
  end

  describe "handler isolation" do
    test "failing handler does not affect event emission" do
      :telemetry.attach(
        "test-failing-handler",
        [:shepherd, :metrics, :ingested],
        fn _, _, metadata, _ ->
          send(:pipeline_test, {:before_fail, metadata.device_id})
          raise "intentional failure"
        end,
        nil
      )

      :telemetry.attach(
        "test-handler",
        [:shepherd, :metrics, :ingested],
        fn _, _, metadata, _ ->
          send(:pipeline_test, {:after_fail, metadata.device_id})
        end,
        nil
      )

      on_exit(fn ->
        try do
          :telemetry.detach("test-failing-handler")
        rescue
          _ -> :ok
        end

        try do
          :telemetry.detach("test-handler")
        rescue
          _ -> :ok
        end
      end)

      # Should not raise, handlers are isolated
      :telemetry.execute(
        [:shepherd, :metrics, :ingested],
        %{count: 1},
        %{device_id: 42, metrics: []}
      )

      assert_receive {:before_fail, 42}
      assert_receive {:after_fail, 42}
    end
  end
end
