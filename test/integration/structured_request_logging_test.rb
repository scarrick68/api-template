require "test_helper"

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

    payload = find_http_request_log(captured_payloads, path: "/api/v1/users/me")

    assert payload, "Expected a structured http_request log"
    assert_equal user.id, payload["user_id"]
    assert_nil payload["admin_id"]
    assert_equal "GET", payload["method"]
    assert_equal "/api/v1/users/me", payload["path"]
    assert_equal "Api::V1::UsersController", payload["controller"]
    assert_equal "me", payload["action"]
    assert_equal 200, payload["status"]
    assert payload["request_id"].present?
    assert payload.key?("visitor_token")
  end

  test "admin session auth logs structured http request" do
    admin = create(:admin, password: "password123", password_confirmation: "password123")
    captured_payloads = []

    capture_structured_request_logs(captured_payloads) do
      subscribe_to_structured_request_logging do
        post "/admins/sign_in", params: {
          admin: {
            email: admin.email,
            password: "password123"
          }
        }
      end
    end

    payload = find_http_request_log(captured_payloads, path: "/admins/sign_in")

    assert payload, "Expected an admin session auth http_request log"
    assert_equal "POST", payload["method"]
    assert_equal "Admins::SessionsController", payload["controller"]
    assert_equal "create", payload["action"]
    assert_equal admin.id, payload["admin_id"]
    assert_nil payload["user_id"]
    assert payload["request_id"].present?
  end

  test "token auth logs structured http request" do
    user = create(:user, password: "password123", password_confirmation: "password123")
    captured_payloads = []

    capture_structured_request_logs(captured_payloads) do
      subscribe_to_structured_request_logging do
        post "/auth/sign_in", params: {
          email: user.email,
          password: "password123"
        }, as: :json
      end
    end

    assert_response :success

    payload = find_http_request_log(captured_payloads, path: "/auth/sign_in")

    assert payload, "Expected a token auth http_request log"
    assert_equal "POST", payload["method"]
    assert_equal "Auth::SessionsController", payload["controller"]
    assert_equal "create", payload["action"]
    assert_equal user.id, payload["user_id"]
    assert_nil payload["admin_id"]
    assert payload["request_id"].present?
  end

  test "admin tools route logs structured http request" do
    admin = create(:admin)
    sign_in admin, scope: :admin
    captured_payloads = []

    capture_structured_request_logs(captured_payloads) do
      subscribe_to_structured_request_logging do
        get "/admin/tools"
      end
    end

    assert_response :success

    payload = find_http_request_log(captured_payloads, path: "/admin/tools")

    assert payload, "Expected an admin tools http_request log"
    assert_equal "GET", payload["method"]
    assert_equal "AdminToolsController", payload["controller"]
    assert_equal "index", payload["action"]
    assert_nil payload["user_id"]
    assert_equal admin.id, payload["admin_id"]
    assert_equal 200, payload["status"]
    assert payload["request_id"].present?
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

      next if Logging::StructuredRequestLog.ignore_event?(event)

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

  def find_http_request_log(captured_payloads, path:)
    captured_payloads.find do |entry|
      entry["event"] == "http_request" && entry["path"] == path
    end
  end

  def parse_json_log(message)
    return unless message.is_a?(String)
    return unless message.start_with?("{")

    JSON.parse(message)
  rescue JSON::ParserError
    nil
  end
end
