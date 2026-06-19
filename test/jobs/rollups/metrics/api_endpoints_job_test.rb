require "test_helper"

class ApiEndpointsJobTest < ActiveJob::TestCase
  test "builds endpoint request, error, avg, and p95 rollups" do
    window_start = Time.zone.parse("2026-06-18 10:00:00 UTC")
    window_end = window_start + 1.hour

    create_api_metric(name: Metric::API_REQUEST_COUNT, value: 1, occurred_at: window_start + 5.minutes, action: "index")
    create_api_metric(name: Metric::API_REQUEST_COUNT, value: 1, occurred_at: window_start + 15.minutes, action: "index")
    create_api_metric(name: Metric::API_REQUEST_COUNT, value: 1, occurred_at: window_start + 25.minutes, action: "show")
    create_api_metric(name: Metric::API_REQUEST_COUNT, value: 1, occurred_at: window_start + 35.minutes, action: "show", status: 404)
    create_api_metric(name: Metric::API_REQUEST_COUNT, value: 1, occurred_at: window_start + 45.minutes, action: "show", status: 500)

    create_api_metric(name: Metric::API_REQUEST_DURATION_MS, value: 100, occurred_at: window_start + 6.minutes, action: "index")
    create_api_metric(name: Metric::API_REQUEST_DURATION_MS, value: 300, occurred_at: window_start + 16.minutes, action: "index")
    create_api_metric(name: Metric::API_REQUEST_DURATION_MS, value: 200, occurred_at: window_start + 26.minutes, action: "show")

    assert_difference "Rollup.count", 8 do
      Metrics::Rollups::ApiEndpointsJob.perform_now(
        period: "hour",
        window_start: window_start,
        window_end: window_end
      )
    end

    assert_in_delta 2.0, rollup_value("observability.api.endpoint.requests", "hour", window_start, controller: "Api::V1::UsersController", action: "index"), 0.001
    assert_in_delta 3.0, rollup_value("observability.api.endpoint.requests", "hour", window_start, controller: "Api::V1::UsersController", action: "show"), 0.001
    assert_in_delta 200.0, rollup_value("observability.api.endpoint.duration.avg_ms", "hour", window_start, controller: "Api::V1::UsersController", action: "index"), 0.001
    assert_in_delta 200.0, rollup_value("observability.api.endpoint.duration.avg_ms", "hour", window_start, controller: "Api::V1::UsersController", action: "show"), 0.001
    assert_in_delta 290.0, rollup_value("observability.api.endpoint.duration.p95_ms", "hour", window_start, controller: "Api::V1::UsersController", action: "index"), 0.001
    assert_in_delta 200.0, rollup_value("observability.api.endpoint.duration.p95_ms", "hour", window_start, controller: "Api::V1::UsersController", action: "show"), 0.001
    assert_in_delta 1.0, rollup_value("observability.api.endpoint.client_errors", "hour", window_start, controller: "Api::V1::UsersController", action: "show"), 0.001
    assert_in_delta 1.0, rollup_value("observability.api.endpoint.server_errors", "hour", window_start, controller: "Api::V1::UsersController", action: "show"), 0.001
  end

  test "skips rollups when an endpoint dimension is blank (ex: controller / action is nil)" do
    window_start = Time.zone.parse("2026-06-18 10:00:00 UTC")
    window_end = window_start + 1.hour

    create(
      :metric,
      name: Metric::API_REQUEST_COUNT,
      metric_type: "counter",
      value: 1,
      occurred_at: window_start + 5.minutes,
      labels: {
        method: "GET",
        controller: nil,
        action: "index",
        status: 200
      },
      properties: { path: "/api/v1/users" }
    )

    assert_no_difference "Rollup.count" do
      Metrics::Rollups::ApiEndpointsJob.perform_now(
        period: "hour",
        window_start: window_start,
        window_end: window_end
      )
    end
  end

  private

  def create_api_metric(name:, value:, occurred_at:, action:, status: 200)
    create(
      :metric,
      name: name,
      metric_type: metric_type_for(name),
      value: value,
      occurred_at: occurred_at,
      labels: {
        method: "GET",
        controller: "Api::V1::UsersController",
        action: action,
        status: status
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

  def rollup_value(name, interval, time, dimensions)
    Rollup.find_by!(
      name: name,
      interval: interval,
      time: time,
      dimensions: dimensions.stringify_keys
    ).value
  end
end
