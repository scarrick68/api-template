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
        assert_equal true, response.parsed_body["success"]
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
        assert_equal true, response.parsed_body["success"]
        assert_equal "Hello, #{name}!", response.parsed_body["message"]
        assert_equal true, response.parsed_body["cached"], "Expected cache hit on second request"
      end
    end
  end
end
