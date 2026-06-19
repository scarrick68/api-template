require "test_helper"

class ApiObservabilityJobTest < ActiveJob::TestCase
  test "builds global duration p95 rollup for hourly window" do
    window_start = Time.zone.parse("2026-06-18 10:00:00 UTC")
    window_end = window_start + 1.hour

    create_api_metric(name: Metric::API_REQUEST_DURATION_MS, value: 100, occurred_at: window_start + 6.minutes)
    create_api_metric(name: Metric::API_REQUEST_DURATION_MS, value: 300, occurred_at: window_start + 16.minutes)
    create_api_metric(name: Metric::API_REQUEST_DURATION_MS, value: 200, occurred_at: window_start + 26.minutes)

    Metrics::Rollups::ApiObservabilityJob.perform_now(
      period: "hour",
      window_start: window_start,
      window_end: window_end
    )

    assert_in_delta 290.0, rollup_value("observability.api.duration.p95_ms", "hour", window_start), 0.001
  end

  test "is idempotent when run multiple times for the same window" do
    window_start = Time.zone.parse("2026-06-18 12:00:00 UTC")
    window_end = window_start + 1.hour

    create_api_metric(
      name: Metric::API_REQUEST_DURATION_MS,
      value: 150,
      occurred_at: window_start + 2.minutes
    )

    Metrics::Rollups::ApiObservabilityJob.perform_now(
      period: "hour",
      window_start: window_start,
      window_end: window_end
    )

    first_value = rollup_value(
      "observability.api.duration.p95_ms",
      "hour",
      window_start
    )

    assert_no_difference "Rollup.count" do
      Metrics::Rollups::ApiObservabilityJob.perform_now(
        period: "hour",
        window_start: window_start,
        window_end: window_end
      )
    end

    second_value = rollup_value(
      "observability.api.duration.p95_ms",
      "hour",
      window_start
    )

    assert_in_delta first_value, second_value, 0.001
  end

  test "recomputes rollups when new metrics arrive within the window" do
    window_start = Time.zone.parse("2026-06-18 12:00:00 UTC")
    window_end = window_start + 1.hour

    create_api_metric(
      name: Metric::API_REQUEST_DURATION_MS,
      value: 100,
      occurred_at: window_start + 2.minutes
    )

    Metrics::Rollups::ApiObservabilityJob.perform_now(
      period: "hour",
      window_start: window_start,
      window_end: window_end
    )

    assert_in_delta(
      100.0,
      rollup_value("observability.api.duration.p95_ms", "hour", window_start),
      0.001
    )

    create_api_metric(
      name: Metric::API_REQUEST_DURATION_MS,
      value: 200,
      occurred_at: window_start + 30.minutes
    )

    create_api_metric(
      name: Metric::API_REQUEST_DURATION_MS,
      value: 300,
      occurred_at: window_start + 45.minutes
    )

    Metrics::Rollups::ApiObservabilityJob.perform_now(
      period: "hour",
      window_start: window_start,
      window_end: window_end
    )

    assert_in_delta(
      290.0,
      rollup_value("observability.api.duration.p95_ms", "hour", window_start),
      0.001
    )
  end

  test "supports daily period" do
    day_start = Time.zone.parse("2026-06-17 00:00:00 UTC")
    day_end = day_start + 1.day

    create_api_metric(name: Metric::API_REQUEST_DURATION_MS, value: 425, occurred_at: day_start + 4.hours)

    Metrics::Rollups::ApiObservabilityJob.perform_now(
      period: "day",
      window_start: day_start,
      window_end: day_end
    )

    assert_in_delta 425.0, rollup_value("observability.api.duration.p95_ms", "day", day_start), 0.001
  end

  private

  def create_api_metric(name:, value:, occurred_at:)
    create(
      :metric,
      name: name,
      metric_type: metric_type_for(name),
      value: value,
      occurred_at: occurred_at,
      labels: {
        method: "GET",
        controller: "Api::V1::UsersController",
        action: "index",
        status: 200
      },
      properties: {
        path: "/api/v1/users"
      }
    )
  end

  def metric_type_for(name)
    return "histogram" if name == Metric::API_REQUEST_DURATION_MS

    "counter"
  end

  def rollup_value(name, interval, time)
    Rollup.find_by!(
      name: name,
      interval: interval,
      time: time,
      dimensions: {}
    ).value
  end
end
