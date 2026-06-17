require "test_helper"
require "support/application_dispatch_test"

class ApiDocsTest < ApplicationDispatchTest
  include Devise::Test::IntegrationHelpers

  test "docs UI route is hidden outside development for anonymous users" do
    with_stubbed_production_env do
      get "/docs"

      assert_response :not_found
    end
  end

  test "openapi route is hidden outside development for anonymous users" do
    with_stubbed_production_env do
      get "/openapi.yml"

      assert_response :not_found
    end
  end

  test "docs UI route is hidden outside development for non-admin users" do
    with_stubbed_production_env do
      sign_in create(:user)

      get "/docs"

      assert_response :not_found
    end
  end

  test "openapi route is hidden outside development for non-admin users" do
    with_stubbed_production_env do
      sign_in create(:user)

      get "/openapi.yml"

      assert_response :not_found
    end
  end

  test "docs UI route is available outside development for admin users" do
    with_stubbed_production_env do
      sign_in create(:user, :admin), scope: :user

      get "/docs"

      assert_response :success
      assert_includes response.body, "<redoc"
      assert_includes response.body, "/openapi.yml"
    end
  end

  test "openapi route is available outside development for admin users" do
    with_stubbed_production_env do
      sign_in create(:user, :admin), scope: :user

      get "/openapi.yml"

      assert_response :success
      assert_includes response.media_type, "application/yaml"
      assert_includes response.body, "openapi: 3.1.0"
    end
  end

  test "legacy api docs UI route is unavailable" do
    with_stubbed_production_env do
      get "/api/docs"

      assert_response :not_found
    end
  end

  test "legacy api openapi route is unavailable" do
    with_stubbed_production_env do
      get "/api/openapi.yml"

      assert_response :not_found
    end
  end

  test "token-authenticated user cannot access docs outside development" do
    with_stubbed_production_env do
      headers = auth_headers_for(create(:user))

      get "/docs", headers: headers

      assert_response :not_found
    end
  end

  test "token-authenticated admin cannot access docs outside development" do
    with_stubbed_production_env do
      headers = auth_headers_for(create(:user, :admin))

      get "/openapi.yml", headers: headers

      assert_response :not_found
    end
  end

  test "docs UI route is available in development" do
    with_stubbed_development_env do
      get "/docs"

      assert_response :success
      assert_includes response.body, "<redoc"
      assert_includes response.body, "/openapi.yml"
    end
  end

  test "openapi route is available in development" do
    with_stubbed_development_env do
      get "/openapi.yml"

      assert_response :success
      assert_includes response.media_type, "application/yaml"
      assert_includes response.body, "openapi: 3.1.0"
    end
  end

  private

  def with_stubbed_production_env
    Rails.env.stubs(:production?).returns(true)
    Rails.env.stubs(:development?).returns(false)
    yield
  ensure
    Rails.env.unstub(:production?)
    Rails.env.unstub(:development?)
  end

  def with_stubbed_development_env
    Rails.env.stubs(:production?).returns(false)
    Rails.env.stubs(:development?).returns(true)
    yield
  ensure
    Rails.env.unstub(:production?)
    Rails.env.unstub(:development?)
  end
end
