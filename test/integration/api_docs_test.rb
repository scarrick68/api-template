require "test_helper"

class ApiDocsTest < ApplicationDispatchTest
  test "anonymous users are redirected to admin sign-in for docs UI" do
    get "/docs"

    assert_redirected_to "/admins/sign_in"
  end

  test "anonymous users are redirected to admin sign-in for openapi" do
    get "/openapi.yml"

    assert_redirected_to "/admins/sign_in"
  end

  test "non-admin user sessions are redirected to admin sign-in for docs UI" do
    sign_in create(:user)

    get "/docs"

    assert_redirected_to "/admins/sign_in"
  end

  test "non-admin user sessions are redirected to admin sign-in for openapi" do
    sign_in create(:user)

    get "/openapi.yml"

    assert_redirected_to "/admins/sign_in"
  end

  test "docs UI route is available for admin sessions" do
    sign_in create(:admin), scope: :admin

    get "/docs"

    assert_response :success
    assert_includes response.body, "<redoc"
    assert_includes response.body, "/openapi.yml"
  end

  test "openapi route is available for admin sessions" do
    sign_in create(:admin), scope: :admin

    get "/openapi.yml"

    assert_response :success
    assert_includes response.media_type, "application/yaml"
    assert_includes response.body, "openapi: 3.1.0"
  end

  test "legacy api docs UI route is unavailable" do
    get "/api/docs"

    assert_response :not_found
  end

  test "legacy api openapi route is unavailable" do
    get "/api/openapi.yml"

    assert_response :not_found
  end

  test "token-authenticated user cannot access docs UI" do
    headers = auth_headers_for(create(:user))

    get "/docs", headers: headers

    assert_redirected_to "/admins/sign_in"
  end

  test "token-authenticated admin-like user cannot access openapi without admin session" do
    headers = auth_headers_for(create(:user, :admin))

    get "/openapi.yml", headers: headers

    assert_redirected_to "/admins/sign_in"
  end
end
