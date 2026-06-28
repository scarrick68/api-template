require "test_helper"

module Api
  module V1
    class StructuredRequestLoggingTest < ApplicationDispatchTest
      test "api request logs structured request payload with request and actor context" do
        user = create(:user, email: "structured-logging@example.com")
        captured_payloads = []

        capture_structured_request_logs(captured_payloads) do
          subscribe_to_structured_request_logging do
            get "/api/v1/users/me", headers: auth_headers_for(user)
          end
        end

        assert_response :success

        payload = captured_payloads.find { |entry| entry["event"] == "http_request" && entry["path"] == "/api/v1/users/me" }

        assert payload, "Expected a structured http_request log"
        assert_equal user.id, payload["user_id"]
        assert_equal "GET", payload["method"]
        assert_equal "/api/v1/users/me", payload["path"]
        assert_equal "Api::V1::UsersController", payload["controller"]
        assert_equal "me", payload["action"]
        assert_equal 200, payload["status"]
        assert payload["request_id"].present?
        assert payload.key?("visitor_token")
      end

      private

      def capture_structured_request_logs(captured_payloads)
        Rails.logger.stubs(:info).with do |message|
          payload = parse_json_log(message)
          captured_payloads << payload if payload

          true
        end

        yield
      end

      def subscribe_to_structured_request_logging
        callback = lambda do |*args|
          event = ActiveSupport::Notifications::Event.new(*args)

          next unless structured_request_log_event?(event)

          payload = Logging::StructuredRequestLog.lograge_custom_options(event)
          Rails.logger.info(Lograge::Formatters::Json.new.call(payload))
        end

        ActiveSupport::Notifications.subscribed(
          callback,
          "process_action.action_controller"
        ) do
          yield
        end
      end

      def structured_request_log_event?(event)
        event.payload[:controller] == "Api::V1::UsersController" &&
          event.payload[:action] == "me" &&
          !Logging::StructuredRequestLog.ignore_event?(event)
      end

      def parse_json_log(message)
        return unless message.is_a?(String)
        return unless message.start_with?("{")

        JSON.parse(message)
      rescue JSON::ParserError
        nil
      end
    end
  end
end
