require "test_helper"

class RateLimitingTest < ActionDispatch::IntegrationTest
  setup do
    @original_rack_attack_store = Rack::Attack.cache.store
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    clear_rack_attack_cache!
  end

  teardown do
    Rack::Attack.cache.store = @original_rack_attack_store
  end

  test "throttles repeated auth sign in attempts" do
    limit = Rack::Attack::AUTH_SIGN_IN_LIMIT

    limit.times do
      post "/auth/sign_in", params: {
        email: "missing@example.com",
        password: "password123"
      }, as: :json

      assert_response :unauthorized
    end

    post "/auth/sign_in", params: {
      email: "missing@example.com",
      password: "password123"
    }, as: :json

    assert_response :too_many_requests
  end

  test "throttles write-heavy user endpoints" do
    limit = Rack::Attack::USERS_WRITE_LIMIT

    limit.times do
      post "/api/v1/users", params: {
        name: "New User",
        email: "invalid-email",
        password: "password123",
        password_confirmation: "password123"
      }, as: :json

      assert_response :unprocessable_entity
    end

    post "/api/v1/users", params: {
      name: "New User",
      email: "invalid-email",
      password: "password123",
      password_confirmation: "password123"
    }, as: :json

    assert_response :too_many_requests
  end

  private

  def clear_rack_attack_cache!
    cache = Rack::Attack.cache.store
    cache.clear if cache.respond_to?(:clear)
  end
end
