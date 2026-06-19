require "test_helper"

class RollupHelpersTest < ActiveSupport::TestCase
  HelperHost = Class.new do
    include Metrics::RollupHelpers

    def build_window_public(period:, window_start: nil, window_end: nil)
      send(:build_window, period: period, window_start: window_start, window_end: window_end)
    end

    def upsert_rollup_public(name:, window:, value:, dimensions: {})
      send(:upsert_rollup, name: name, window: window, value: value, dimensions: dimensions)
    end

    def p95_public(scope)
      send(:p95, scope)
    end
  end

  setup do
    @host = HelperHost.new
    @base_time = Time.zone.parse("2026-06-18 10:00:00 UTC")
  end

  test "build_window rejects invalid period" do
    assert_raises(ArgumentError) do
      @host.build_window_public(period: "week")
    end
  end

  test "build_window rejects invalid range" do
    start_time = @base_time

    assert_raises(ArgumentError) do
      @host.build_window_public(
        period: "hour",
        window_start: start_time,
        window_end: start_time
      )
    end
  end

  test "build_window accepts string timestamps" do
    window = hourly_window

    assert_equal "hour", window.period
    assert_equal @base_time, window.start_time
    assert_equal @base_time + 1.hour, window.end_time
  end

  test "upsert_rollup does nothing for nil value" do
    assert_no_difference "Rollup.count" do
      @host.upsert_rollup_public(
        name: "observability.api.requests.total",
        window: hourly_window,
        value: nil
      )
    end
  end

  test "upsert_rollup writes rollup with dimensions" do
    window = hourly_window

    @host.upsert_rollup_public(
      name: "observability.api.endpoint.requests",
      window: window,
      value: 2,
      dimensions: {
        controller: "Api::V1::UsersController",
        action: "index"
      }
    )

    row = Rollup.find_by!(
      name: "observability.api.endpoint.requests",
      interval: "hour",
      time: window.start_time,
      dimensions: {
        "controller" => "Api::V1::UsersController",
        "action" => "index"
      }
    )

    assert_equal 2.0, row.value
  end

  test "upsert_rollup overwrites existing rollup row when values have incremented in the given interval" do
    window = hourly_window

    @host.upsert_rollup_public(
      name: "observability.api.requests.total",
      window: window,
      value: 1
    )

    @host.upsert_rollup_public(
      name: "observability.api.requests.total",
      window: window,
      value: 2
    )

    rows = Rollup.where(
      name: "observability.api.requests.total",
      interval: "hour",
      time: window.start_time,
      dimensions: {}
    )

    assert_equal 1, rows.count

    assert_equal(
      2.0,
      rows.first.value.to_f
    )
  end

  test "p95 returns percentile for numeric values" do
    occurred_at = @base_time

    create(
      :metric,
      name: Metric::API_REQUEST_DURATION_MS,
      metric_type: "histogram",
      value: 100,
      occurred_at: occurred_at
    )

    create(
      :metric,
      name: Metric::API_REQUEST_DURATION_MS,
      metric_type: "histogram",
      value: 200,
      occurred_at: occurred_at
    )

    create(
      :metric,
      name: Metric::API_REQUEST_DURATION_MS,
      metric_type: "histogram",
      value: 300,
      occurred_at: occurred_at
    )

    scope = Metric.where(
      name: Metric::API_REQUEST_DURATION_MS,
      occurred_at: occurred_at
    )

    value = @host.p95_public(scope)

    assert_in_delta 290.0, value.to_f, 0.001
  end

  private

  def hourly_window
    @host.build_window_public(
      period: "hour",
      window_start: @base_time,
      window_end: @base_time + 1.hour
    )
  end
end
