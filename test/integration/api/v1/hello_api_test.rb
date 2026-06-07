require "test_helper"

module Api
  module V1
    class HelloApiTest < ActionDispatch::IntegrationTest
      setup do
        assert ActiveRecord::Base.connection.data_source_exists?("solid_cache_entries"),
               "solid_cache_entries table is missing; run test DB migrations"

        @original_cache = Rails.cache
        Rails.cache = ActiveSupport::Cache.lookup_store(:solid_cache_store, namespace: "hello_api_test")
        ActiveRecord::Base.connection.execute("DELETE FROM solid_cache_entries")
      end

      teardown do
        Rails.cache = @original_cache
      end

      test "request succeeds and writes greeting to solid cache" do
        name = "cache-#{SecureRandom.hex(4)}"
        cache_key = "hello:greeting:#{name}"

        get "/api/v1/hello", params: { name: name }

        assert_response :success
        assert response.headers["X-Request-Id"].present?
        assert_equal true, response.parsed_body["success"]
        assert_equal response.headers["X-Request-Id"], response.parsed_body["request_id"]
        assert_equal "Hello, #{name}!", response.parsed_body["message"]
        assert_equal false, response.parsed_body["cached"], "Expected cache miss on first request"
        assert Rails.cache.exist?(cache_key)
        assert_equal "Hello, #{name}!", Rails.cache.read(cache_key)
      end

      test "cached greeting is returned on subsequent request" do
        name = "cache-#{SecureRandom.hex(4)}"
        cache_key = "hello:greeting:#{name}"
        Rails.cache.write(cache_key, "Hello, #{name}!", expires_in: 10.minutes)

        get "/api/v1/hello", params: { name: name }

        assert_response :success
        assert response.headers["X-Request-Id"].present?
        assert_equal true, response.parsed_body["success"]
        assert_equal response.headers["X-Request-Id"], response.parsed_body["request_id"]
        assert_equal "Hello, #{name}!", response.parsed_body["message"]
        assert_equal true, response.parsed_body["cached"], "Expected cache hit on second request"
      end

      test "invalid input renders standardized validation error payload" do
        get "/api/v1/hello", params: { name: "a" * 51 }

        assert_response :unprocessable_entity
        assert response.headers["X-Request-Id"].present?
        assert_equal false, response.parsed_body["success"]
        assert_equal "unprocessable_entity", response.parsed_body["error_type"]
        assert_equal "Validation failed", response.parsed_body["errors"].first
        assert_includes response.parsed_body["errors"], "Name is too long (maximum is 50 characters)"
        assert_equal response.headers["X-Request-Id"], response.parsed_body["request_id"]
      end

      test "controller uses api v1 base controller" do
        assert_equal Api::V1::BaseController, Api::V1::HelloController.superclass
      end
    end
  end
end
