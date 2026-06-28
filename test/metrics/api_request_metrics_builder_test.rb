require "test_helper"

class ApiRequestMetricsBuilderTest < ActiveSupport::TestCase
  test "builds count and duration rows for successful request" do
    payload = payload_for(status: 200)

    rows = ApiRequestMetricsBuilder.call(payload)

    assert_equal 5, rows.size
    assert_equal [
      Metric::API_REQUEST_COUNT,
      Metric::API_REQUEST_DURATION_MS,
      Metric::API_REQUEST_DB_DURATION_MS,
      Metric::API_REQUEST_VIEW_DURATION_MS,
      Metric::API_REQUEST_APP_COMPUTE_DURATION_MS
    ].sort, rows.map { |row| row[:name] }.sort

    rows.each do |row|
      assert Schemas::DrySchemaValidator.validate!(
        Schemas::ApiRequestMetricRow,
        row.except(:created_at, :updated_at)
      )
    end
  end

  test "does not emit separate client error metric rows" do
    rows = ApiRequestMetricsBuilder.call(payload_for(status: 404))

    assert_equal 5, rows.size
    assert_equal [
      Metric::API_REQUEST_COUNT,
      Metric::API_REQUEST_DURATION_MS,
      Metric::API_REQUEST_DB_DURATION_MS,
      Metric::API_REQUEST_VIEW_DURATION_MS,
      Metric::API_REQUEST_APP_COMPUTE_DURATION_MS
    ].sort, rows.map { |row| row[:name] }.sort
  end

  test "does not emit separate server error metric rows" do
    rows = ApiRequestMetricsBuilder.call(payload_for(status: 500))

    assert_equal 5, rows.size
    assert_equal [
      Metric::API_REQUEST_COUNT,
      Metric::API_REQUEST_DURATION_MS,
      Metric::API_REQUEST_DB_DURATION_MS,
      Metric::API_REQUEST_VIEW_DURATION_MS,
      Metric::API_REQUEST_APP_COMPUTE_DURATION_MS
    ].sort, rows.map { |row| row[:name] }.sort
  end

  private

  def payload_for(status:)
    {
      occurred_at: Time.current.change(usec: 0).iso8601,
      request_id: "req-#{SecureRandom.hex(4)}",
      user_id: nil,
      visitor_token: "visitor-1",
      method: "GET",
      path: "/api/v1/users",
      controller: "Api::V1::UsersController",
      action: "index",
      status: status,
      duration_ms: 23,
      db_duration_ms: 8,
      view_duration_ms: 2,
      app_compute_duration_ms: 13
    }
  end
end
