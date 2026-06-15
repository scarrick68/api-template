require "test_helper"
require "ostruct"

module Subscribers
  module Observability
    class ApiRequestSubscriberTest < ActiveSupport::TestCase
      test "captures api controller requests" do
        request_id = "req-123"
        payload = {
          method: "GET",
          path: "/api/v1/users/me",
          controller: "Api::V1::UsersController",
          action: "me",
          status: 200,
          request: OpenStruct.new(request_id: request_id),
          user_id: 42,
          db_runtime: 1.5,
          view_runtime: 0.0
        }

        started_at = Time.current
        finished_at = started_at + 1

        assert_difference "Metric.count", 1 do
          ApiRequestSubscriber.call(
            "process_action.action_controller",
            started_at,
            finished_at,
            "event-id",
            payload
          )
        end

        metric = Metric.last

        assert_equal "observability.api.request", metric.name
        assert_equal request_id, metric.request_id
        assert_equal 42, metric.user_id

        properties = metric.properties.with_indifferent_access
        assert_equal payload[:method], properties[:method]
        assert_equal payload[:path], properties[:path]
        assert_equal payload[:controller], properties[:controller]
        assert_equal payload[:action], properties[:action]
        assert_equal payload[:status], properties[:status]
      end

      test "ignores non api controller requests (does not include Api namespace prefix)" do
        payload = {
          method: "GET",
          path: "/users/sign_in",
          controller: "Users::SessionsController",
          action: "new",
          status: 200,
          db_runtime: 1.0,
          view_runtime: 2.0
        }

        started_at = Time.current
        finished_at = started_at + 0.01

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
