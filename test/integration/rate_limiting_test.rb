require "test_helper"

class RateLimitingTest < ActionDispatch::IntegrationTest
  include ActiveSupport::Testing::TimeHelpers

  setup do
    @original_rack_attack_store = Rack::Attack.cache.store
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

    # Keep all requests inside a single throttle period window.
    travel_to Time.zone.local(2026, 1, 15, 12, 0, 0)
    clear_rack_attack_cache!
  end

  teardown do
    clear_rack_attack_cache!
    travel_back
    Rack::Attack.cache.store = @original_rack_attack_store
  end

  test "throttles repeated auth sign in attempts" do
    limit = Rack::Attack::AUTH_SIGN_IN_LIMIT
    headers = rate_limit_headers("192.0.2.10")

    limit.times do
      post "/auth/sign_in", params: {
        email: "missing@example.com",
        password: "password123"
      }, headers:, as: :json

      assert_response :unauthorized
    end

    post "/auth/sign_in", params: {
      email: "missing@example.com",
      password: "password123"
    }, headers:, as: :json

    assert_response :too_many_requests
  end

  test "throttles write-heavy user endpoints" do
    limit = Rack::Attack::USERS_WRITE_LIMIT
    headers = rate_limit_headers("192.0.2.20")

    limit.times do
      post "/api/v1/users", params: {
        name: "New User",
        email: "invalid-email",
        password: "password123",
        password_confirmation: "password123"
      }, headers:, as: :json

      assert_response :unprocessable_entity
    end

    post "/api/v1/users", params: {
      name: "New User",
      email: "invalid-email",
      password: "password123",
      password_confirmation: "password123"
    }, headers:, as: :json

    assert_response :too_many_requests
  end

  private

  def clear_rack_attack_cache!
    cache = Rack::Attack.cache.store
    cache.clear if cache.respond_to?(:clear)
  end

  def rate_limit_headers(ip)
    {
      "REMOTE_ADDR" => ip,
      "HTTP_X_FORWARDED_FOR" => ip
    }
  end
end
