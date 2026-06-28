require "test_helper"

module Logging
  class StructuredRequestLogTest < ActiveSupport::TestCase
    EventStub = Struct.new(:time, :duration, :payload)
    RequestStub = Struct.new(:request_id, :remote_ip)

    test "builds stable request schema from process_action payload" do
      event = build_event(
        time: Time.utc(2026, 6, 28),
        duration: 34.21,
        payload: {
          request: build_request(request_id: "req-123"),
          user_id: 42,
          visitor_token: "visitor-abc",
          method: "GET",
          path: "/api/v1/users/me",
          controller: "Api::V1::UsersController",
          action: "me",
          status: 200,
          db_runtime: 6.78,
          remote_ip: "203.0.113.10"
        }
      )

      output = StructuredRequestLog.lograge_custom_options(event)

      assert_equal "2026-06-28T00:00:00.000Z", output[:timestamp]
      assert_equal "INFO", output[:severity]
      assert_equal "http_request", output[:event]
      assert_equal "req-123", output[:request_id]
      assert_nil output[:admin_id]
      assert_equal 42, output[:user_id]
      assert_equal "visitor-abc", output[:visitor_token]
      assert_equal "GET", output[:method]
      assert_equal "/api/v1/users/me", output[:path]
      assert_equal "Api::V1::UsersController", output[:controller]
      assert_equal "me", output[:action]
      assert_equal 200, output[:status]
      assert_equal 34.21, output[:request_duration]
      assert_equal 6.78, output[:db_duration]
      assert_equal "203.0.113.10", output[:remote_ip]
    end

    test "formats structured request payload as json" do
      event = build_event(
        time: Time.utc(2026, 6, 28, 9, 0, 0),
        duration: 15.6,
        payload: {
          request: build_request(
            request_id: "req-json",
            remote_ip: "203.0.113.50"
          ),
          method: "GET",
          path: "/api/v1/users/me",
          controller: "Api::V1::UsersController",
          action: "me",
          status: 200,
          user_id: 42,
          visitor_token: "visitor-xyz",
          db_runtime: 2.3
        }
      )

      payload = StructuredRequestLog.lograge_custom_options(event)
      parsed = JSON.parse(Lograge::Formatters::Json.new.call(payload))

      assert_equal "http_request", parsed["event"]
      assert_equal "GET", parsed["method"]
      assert_equal "/api/v1/users/me", parsed["path"]
      assert_equal 15.6, parsed["request_duration"]
      assert_equal 2.3, parsed["db_duration"]
      assert_equal "203.0.113.50", parsed["remote_ip"]
    end

    test "prefers explicit payload request_id" do
      event = build_event(
        time: Time.utc(2026, 6, 28, 12, 0, 0),
        duration: 12.3,
        payload: {
          request: build_request(request_id: "req-from-request"),
          request_id: "req-explicit",
          method: "POST",
          path: "/api/v1/users",
          controller: "Api::V1::UsersController",
          action: "create",
          status: 201
        }
      )

      output = StructuredRequestLog.lograge_custom_options(event)

      assert_equal "req-explicit", output[:request_id]
    end

    test "handles missing timing fields" do
      event = build_event(
        time: Time.utc(2026, 6, 28, 12, 0, 0),
        duration: nil,
        payload: {
          request_id: "req-explicit",
          method: "POST",
          path: "/api/v1/users",
          controller: "Api::V1::UsersController",
          action: "create",
          status: 201
        }
      )

      output = StructuredRequestLog.lograge_custom_options(event)

      assert_nil output[:request_duration]
      assert_nil output[:db_duration]
      assert_nil output[:remote_ip]
      assert_equal "2026-06-28T12:00:00.000Z", output[:timestamp]
    end

    test "uses request remote_ip when payload remote_ip is absent" do
      event = build_event(
        payload: {
          request: build_request(
            request_id: "req-remote",
            remote_ip: "203.0.113.55"
          ),
          method: "GET",
          path: "/up",
          controller: "Rails::HealthController",
          action: "show",
          status: 200
        }
      )

      output = StructuredRequestLog.lograge_custom_options(event)

      assert_equal "203.0.113.55", output[:remote_ip]
    end

    test "ignores non-http events" do
      event = build_event(
        payload: {
          channel_class: "NotificationsChannel",
          action: "subscribed"
        }
      )

      assert StructuredRequestLog.ignore_event?(event)
    end

    test "does not ignore http events" do
      event = build_event(
        payload: {
          method: "GET",
          path: "/up",
          action: "show"
        }
      )

      refute StructuredRequestLog.ignore_event?(event)
    end

    private

    def build_event(time: Time.utc(2026, 6, 28, 14, 0, 0), duration: 5.0, payload: {})
      EventStub.new(time.to_f, duration, payload)
    end

    def build_request(request_id:, remote_ip: nil)
      RequestStub.new(request_id, remote_ip)
    end
  end
end
