require "test_helper"

class ApiRequestMetricsJobTest < ActiveJob::TestCase
  test "writes count and duration metrics for successful api request" do
    user = create(:user)

    payload = api_request_payload(
      user_id: user.id,
      visitor_token: SecureRandom.hex(6),
      path: "/api/v1/users/me",
      action: "me",
      status: 200,
      duration_ms: 13
    )

    assert_difference "Metric.count", 2 do
      ApiRequestMetricsJob.perform_now(payload)
    end

    assert_metric_names_for_request(
      request_id: payload[:request_id],
      expected_names: [
        Metric::API_REQUEST_COUNT,
        Metric::API_REQUEST_DURATION_MS
      ]
    )

    count_metric = metric_for(payload[:request_id], Metric::API_REQUEST_COUNT)
    duration_metric = metric_for(payload[:request_id], Metric::API_REQUEST_DURATION_MS)

    assert_metric_row(
      metric: count_metric,
      expected_name: Metric::API_REQUEST_COUNT,
      expected_metric_type: "counter",
      expected_value: 1,
      expected_payload: payload
    )

    assert_metric_row(
      metric: duration_metric,
      expected_name: Metric::API_REQUEST_DURATION_MS,
      expected_metric_type: "histogram",
      expected_value: payload[:duration_ms],
      expected_payload: payload
    )
  end

  test "writes count and duration metrics for 5xx errors" do
    payload = api_request_payload(
      status: 500,
      duration_ms: 120
    )

    assert_difference "Metric.count", 2 do
      ApiRequestMetricsJob.perform_now(payload)
    end

    assert_metric_names_for_request(
      request_id: payload[:request_id],
      expected_names: [
        Metric::API_REQUEST_COUNT,
        Metric::API_REQUEST_DURATION_MS
      ]
    )

    count_metric = metric_for(payload[:request_id], Metric::API_REQUEST_COUNT)
    duration_metric = metric_for(payload[:request_id], Metric::API_REQUEST_DURATION_MS)

    assert_metric_row(
      metric: count_metric,
      expected_name: Metric::API_REQUEST_COUNT,
      expected_metric_type: "counter",
      expected_value: 1,
      expected_payload: payload
    )

    assert_metric_row(
      metric: duration_metric,
      expected_name: Metric::API_REQUEST_DURATION_MS,
      expected_metric_type: "histogram",
      expected_value: payload[:duration_ms],
      expected_payload: payload
    )
  end

  test "writes count and duration metrics for 4xx errors" do
    payload = api_request_payload(
      status: 404,
      duration_ms: 50
    )

    assert_difference "Metric.count", 2 do
      ApiRequestMetricsJob.perform_now(payload)
    end

    assert_metric_names_for_request(
      request_id: payload[:request_id],
      expected_names: [
        Metric::API_REQUEST_COUNT,
        Metric::API_REQUEST_DURATION_MS
      ]
    )

    count_metric = metric_for(payload[:request_id], Metric::API_REQUEST_COUNT)
    duration_metric = metric_for(payload[:request_id], Metric::API_REQUEST_DURATION_MS)

    assert_metric_row(
      metric: count_metric,
      expected_name: Metric::API_REQUEST_COUNT,
      expected_metric_type: "counter",
      expected_value: 1,
      expected_payload: payload
    )

    assert_metric_row(
      metric: duration_metric,
      expected_name: Metric::API_REQUEST_DURATION_MS,
      expected_metric_type: "histogram",
      expected_value: payload[:duration_ms],
      expected_payload: payload
    )
  end

  test "accepts string keyed payloads from active job serialization" do
    payload = api_request_payload.transform_keys(&:to_s)

    assert_difference "Metric.count", 2 do
      ApiRequestMetricsJob.perform_now(payload)
    end

    assert_metric_names_for_request(
      request_id: payload["request_id"],
      expected_names: [
        Metric::API_REQUEST_COUNT,
        Metric::API_REQUEST_DURATION_MS
      ]
    )
  end

  test "allows anonymous request metrics without user id" do
    payload = api_request_payload(user_id: nil, visitor_token: "anon-visitor")

    ApiRequestMetricsJob.perform_now(payload)

    Metric.where(request_id: payload[:request_id]).find_each do |metric|
      assert_nil metric.user_id
      assert_equal "anon-visitor", metric.visitor_token
    end
  end

  test "raises when payload does not match schema" do
    payload = api_request_payload.except(:duration_ms)

    assert_raises(Schemas::DrySchemaValidator::ValidationError) do
      ApiRequestMetricsJob.perform_now(payload)
    end
  end

  private

  def api_request_payload(overrides = {})
    occurred_at = Time.current.change(usec: 0)

    {
      occurred_at: occurred_at.iso8601,
      request_id: SecureRandom.hex(6),
      user_id: nil,
      visitor_token: nil,
      method: "GET",
      path: "/api/v1/users",
      controller: "Api::V1::UsersController",
      action: "index",
      status: 200,
      duration_ms: 13
    }.merge(overrides)
  end

  def metric_for(request_id, name)
    Metric.find_by!(
      name: name,
      request_id: request_id
    )
  end

  def assert_metric_names_for_request(request_id:, expected_names:)
    assert_equal(
      expected_names.sort,
      Metric.where(request_id: request_id).pluck(:name).sort
    )
  end

  def assert_metric_row(metric:, expected_name:, expected_metric_type:, expected_value:, expected_payload:)
    payload = expected_payload.with_indifferent_access
    expected_occurred_at = Time.iso8601(payload.fetch(:occurred_at))

    assert_equal expected_name, metric.name
    assert_equal expected_metric_type, metric.metric_type
    assert_equal BigDecimal(expected_value.to_s), metric.value
    assert_equal expected_occurred_at.to_i, metric.occurred_at.to_i
    assert_equal payload[:request_id], metric.request_id
    assert_equal_or_nil payload[:user_id], metric.user_id
    assert_equal_or_nil payload[:visitor_token], metric.visitor_token

    assert_equal(
      {
        "method" => payload[:method],
        "controller" => payload[:controller],
        "action" => payload[:action],
        "status" => payload[:status]
      },
      metric.labels
    )

    assert_equal(
      {
        "path" => payload[:path]
      },
      metric.properties
    )

    assert_not_nil metric.created_at
    assert_not_nil metric.updated_at
  end

  def assert_equal_or_nil(expected, actual)
    if expected.nil?
      assert_nil actual
    else
      assert_equal expected, actual
    end
  end
end
