require "test_helper"
require "support/application_dispatch_test"

class ApiDocsTest < ApplicationDispatchTest
  test "docs UI requires authentication outside development" do
    get "/api/docs"

    assert_response :unauthorized
  end

  test "openapi file requires authentication outside development" do
    get "/api/openapi.yml"

    assert_response :unauthorized
  end

  test "docs UI is forbidden for non-admin users outside development" do
    signed_in_user = create(:user, email: "docs-non-admin@example.com")

    get "/api/docs", headers: auth_headers_for(signed_in_user)

    assert_response :forbidden
  end

  test "openapi file is forbidden for non-admin users outside development" do
    signed_in_user = create(:user, email: "docs-non-admin-2@example.com")

    get "/api/openapi.yml", headers: auth_headers_for(signed_in_user)

    assert_response :forbidden
  end

  test "serves redoc UI for admins" do
    signed_in_user = create(:user, :admin, email: "docs-admin@example.com")

    get "/api/docs", headers: auth_headers_for(signed_in_user)

    assert_response :success
    assert_includes response.body, "<redoc"
    assert_includes response.body, "/api/openapi.yml"
  end

  test "serves openapi YAML for admins" do
    signed_in_user = create(:user, :admin, email: "docs-admin-2@example.com")

    get "/api/openapi.yml", headers: auth_headers_for(signed_in_user)

    assert_response :success
    assert_includes response.media_type, "application/yaml"
    assert_includes response.body, "openapi: 3.1.0"
  end
end
