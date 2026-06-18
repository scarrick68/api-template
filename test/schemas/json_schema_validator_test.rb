require "test_helper"

class DrySchemaValidatorTest < ActiveSupport::TestCase
  test "validates api request payload schema" do
    payload = {
      occurred_at: Time.current.change(usec: 0).iso8601,
      request_id: "req-123",
      user_id: 1,
      visitor_token: "visitor-123",
      method: "GET",
      path: "/api/v1/users",
      controller: "Api::V1::UsersController",
      action: "index",
      status: 200,
      duration_ms: 11
    }

    assert Schemas::DrySchemaValidator.validate!(Schemas::ApiRequestMetricsPayload, payload)
  end

  test "raises validation error for invalid payload (invalid status)" do
    payload = {
      occurred_at: Time.current.change(usec: 0).iso8601,
      request_id: "req-123",
      method: "GET",
      path: "/api/v1/users",
      controller: "Api::V1::UsersController",
      action: "index",
      status: 700,
      duration_ms: 11
    }

    assert_raises(Schemas::DrySchemaValidator::ValidationError) do
      Schemas::DrySchemaValidator.validate!(Schemas::ApiRequestMetricsPayload, payload)
    end
  end
end
