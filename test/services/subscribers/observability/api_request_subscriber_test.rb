require "test_helper"
require "ostruct"

module Subscribers
  module Observability
    class ApiRequestSubscriberTest < ActiveSupport::TestCase
      test "enqueues api request metrics job for api controller requests" do
        request_id = "req-123"
        request = OpenStruct.new(
          request_id: request_id,
          env: {}
        )

        payload = {
          method: "GET",
          path: "/api/v1/users/me",
          controller: "Api::V1::UsersController",
          action: "me",
          status: 200,
          request: request,
          user_id: 42,
          visitor_token: "visitor-abc",
          db_runtime: 1.5,
          view_runtime: 0.0
        }

        started_at = Time.current
        finished_at = started_at + 1
        expected_payload = {
          occurred_at: Time.at(started_at.to_f).iso8601,
          request_id: request_id,
          user_id: 42,
          visitor_token: "visitor-abc",
          method: payload[:method],
          path: payload[:path],
          controller: payload[:controller],
          action: payload[:action],
          status: payload[:status],
          duration_ms: 1000,
          db_duration_ms: 2,
          view_duration_ms: 0,
          app_compute_duration_ms: 998
        }

        ApiRequestMetricsJob.expects(:perform_later).with(expected_payload)

        assert_no_difference "Metric.count" do
          ApiRequestSubscriber.call(
            "process_action.action_controller",
            started_at,
            finished_at,
            "event-id",
            payload
          )
        end
      end

      test "forwards nil identity fields when not provided" do
        request_id = "req-456"

        request = OpenStruct.new(
          request_id: request_id,
          env: {}
        )

        payload = {
          method: "GET",
          path: "/api/v1/users",
          controller: "Api::V1::UsersController",
          action: "index",
          status: 200,
          request: request,
          user_id: nil,
          visitor_token: nil
        }

        started_at = Time.current
        finished_at = started_at + 0.1

        expected_payload = {
          occurred_at: Time.at(started_at.to_f).iso8601,
          request_id: request_id,
          user_id: nil,
          visitor_token: nil,
          method: payload[:method],
          path: payload[:path],
          controller: payload[:controller],
          action: payload[:action],
          status: payload[:status],
          duration_ms: 100,
          db_duration_ms: 0,
          view_duration_ms: 0,
          app_compute_duration_ms: 100
        }

        ApiRequestMetricsJob.expects(:perform_later).with(expected_payload)

        ApiRequestSubscriber.call("process_action.action_controller", started_at, finished_at, "event-id", payload)
      end

      test "ignores non api controller requests (does not include Api namespace prefix)" do
        payload = {
          method: "GET",
          path: "/admins/sign_in",
          controller: "Users::SessionsController",
          action: "new",
          status: 200,
          db_runtime: 1.0,
          view_runtime: 2.0
        }

        started_at = Time.current
        finished_at = started_at + 0.01

        ApiRequestMetricsJob.expects(:perform_later).never

        assert_no_difference "Metric.count" do
          ApiRequestSubscriber.call(
            "process_action.action_controller",
            started_at,
            finished_at,
            "event-id",
            payload
          )
        end
      end
    end
  end
end
