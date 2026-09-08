require "test_helper"

module Api
  module V1
    class ErrorsApiTest < ApplicationDispatchTest
      test "create reports error without authentication" do
        captured = nil
        Rails.error.stubs(:report).with do |error, **options|
          captured = { error: error, options: options }
          true
        end

        post "/api/v1/errors", params: {
          client: "mobile",
          origin: "application",
          handled: true,
          error: {
            name: "TypeError",
            message: "Cannot read properties of undefined",
            stack: "TypeError: Cannot read properties of undefined\n at app.js:42:9"
          },
          context: {
            route: "/account",
            app_env: "development"
          }
        }, as: :json

        assert_response :accepted
        assert_conform_response_schema(202)

        assert_not_nil captured
        assert_instance_of Api::V1::ErrorsController::ClientReportedError, captured[:error]
        assert_equal "Cannot read properties of undefined", captured[:error].message
        assert_equal true, captured[:options][:handled]
        assert_equal "client", captured[:options][:source]
        assert_equal "mobile", captured[:options].dig(:context, :client)
        assert_equal "application", captured[:options].dig(:context, :origin)
        assert_equal "/account", captured[:options].dig(:context, :explicit_context, :route)
        assert_nil captured[:options].dig(:context, :user_id)
      end

      test "create includes authenticated user id when token headers are present" do
        signed_in_user = create(:user, email: "errors-user@example.com")

        captured = nil
        Rails.error.stubs(:report).with do |_error, **options|
          captured = options
          true
        end

        post "/api/v1/errors", params: {
          client: "web",
          error: {
            name: "ReferenceError",
            message: "x is not defined"
          }
        }, headers: auth_headers_for(signed_in_user), as: :json

        assert_response :accepted
        assert_conform_response_schema(202)
        assert_equal "web", captured.dig(:context, :client)
        assert_equal "application", captured.dig(:context, :origin)
        assert_equal signed_in_user.id, captured.dig(:context, :user_id)
      end

      test "create normalizes unknown client type" do
        captured = nil
        Rails.error.stubs(:report).with do |_error, **options|
          captured = options
          true
        end

        post "/api/v1/errors", params: {
          client: "desktop",
          error: {
            name: "Error",
            message: "Unknown"
          }
        }, as: :json

        assert_response :accepted
        assert_conform_response_schema(202)
        assert_equal "unknown", captured.dig(:context, :client)
      end

      test "create normalizes missing client type to unknown" do
        captured = nil
        Rails.error.stubs(:report).with do |_error, **options|
          captured = options
          true
        end

        post "/api/v1/errors", params: {
          error: {
            name: "Error",
            message: "Missing client"
          }
        }, as: :json

        assert_response :accepted
        assert_conform_response_schema(202)
        assert_equal "unknown", captured.dig(:context, :client)
      end

      test "create normalizes known client type case-insensitively" do
        captured = nil
        Rails.error.stubs(:report).with do |_error, **options|
          captured = options
          true
        end

        post "/api/v1/errors", params: {
          client: "WEB",
          error: {
            name: "Error",
            message: "Uppercase client"
          }
        }, as: :json

        assert_response :accepted
        assert_conform_response_schema(202)
        assert_equal "web", captured.dig(:context, :client)
      end
    end
  end
end
