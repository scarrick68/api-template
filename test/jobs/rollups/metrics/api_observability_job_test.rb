require "test_helper"

class ApiObservabilityJobTest < ActiveJob::TestCase
  test "builds core rollups for hourly window" do
    window_start = Time.zone.parse("2026-06-18 10:00:00 UTC")
    window_end = window_start + 1.hour

    create_api_metric(name: Metric::API_REQUEST_COUNT, value: 1, occurred_at: window_start + 5.minutes)
    create_api_metric(name: Metric::API_REQUEST_COUNT, value: 1, occurred_at: window_start + 15.minutes)
    create_api_metric(name: Metric::API_REQUEST_COUNT, value: 1, occurred_at: window_start + 25.minutes)

    create_api_metric(name: Metric::API_REQUEST_DURATION_MS, value: 100, occurred_at: window_start + 6.minutes)
    create_api_metric(name: Metric::API_REQUEST_DURATION_MS, value: 300, occurred_at: window_start + 16.minutes)
    create_api_metric(name: Metric::API_REQUEST_DURATION_MS, value: 200, occurred_at: window_start + 26.minutes)

    create_api_metric(name: Metric::API_REQUEST_CLIENT_ERROR_COUNT, value: 1, occurred_at: window_start + 17.minutes)
    create_api_metric(name: Metric::API_REQUEST_ERROR_COUNT, value: 1, occurred_at: window_start + 27.minutes)

    create_api_metric(name: Metric::API_REQUEST_COUNT, value: 50, occurred_at: window_start - 2.hours)

    Metrics::Rollups::ApiObservabilityJob.perform_now(
      period: "hour",
      window_start: window_start,
      window_end: window_end
    )

    assert_in_delta 3.0, rollup_value("observability.api.requests.total", "hour", window_start), 0.001
    assert_in_delta 1.0, rollup_value("observability.api.requests.client_errors", "hour", window_start), 0.001
    assert_in_delta 1.0, rollup_value("observability.api.requests.server_errors", "hour", window_start), 0.001
    assert_in_delta 200.0, rollup_value("observability.api.duration.avg_ms", "hour", window_start), 0.001
    assert_in_delta 290.0, rollup_value("observability.api.duration.p95_ms", "hour", window_start), 0.001
  end

  test "upserts existing rollup rows" do
    window_start = Time.zone.parse("2026-06-18 12:00:00 UTC")
    window_end = window_start + 1.hour

    create_api_metric(name: Metric::API_REQUEST_COUNT, value: 1, occurred_at: window_start + 2.minutes)

    Rollup.create!(
      name: "observability.api.requests.total",
      interval: "hour",
      time: window_start,
      dimensions: {},
      value: 999.0
    )

    assert_no_difference "Rollup.where(name: 'observability.api.requests.total', interval: 'hour', time: window_start, dimensions: {}).count" do
      Metrics::Rollups::ApiObservabilityJob.perform_now(
        period: "hour",
        window_start: window_start,
        window_end: window_end
      )
    end

    assert_in_delta 1.0, rollup_value("observability.api.requests.total", "hour", window_start), 0.001
  end

  test "supports daily period" do
    day_start = Time.zone.parse("2026-06-17 00:00:00 UTC")
    day_end = day_start + 1.day

    create_api_metric(name: Metric::API_REQUEST_COUNT, value: 4, occurred_at: day_start + 4.hours)

    Metrics::Rollups::ApiObservabilityJob.perform_now(
      period: "day",
      window_start: day_start,
      window_end: day_end
    )

    assert_in_delta 4.0, rollup_value("observability.api.requests.total", "day", day_start), 0.001
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
