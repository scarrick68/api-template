# test/integration/admin_tools_access_test.rb

require "test_helper"

class AdminToolsAccessTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "anonymous users are redirected to sign in when trying to access pghero" do
    get "/pghero"

    assert_redirected_to "/users/sign_in"
  end

  test "non-admin users are redirected to sign in when trying to access pghero" do
    sign_in create(:user)

    get "/pghero"

    assert_redirected_to "/users/sign_in"
  end

  test "admin users can access pghero" do
    sign_in create(:user, :admin)

    get "/pghero"

    assert_not_equal "/users/sign_in", response.redirect_url
    assert_not_equal :not_found, response.status
  end

  test "anonymous users are redirected to sign in when trying to access blazer" do
    get "/blazer"

    assert_redirected_to "/users/sign_in"
  end

  test "non-admin users are redirected to sign in when trying to access blazer" do
    sign_in create(:user)

    get "/blazer"

    assert_redirected_to "/users/sign_in"
  end

  test "admin users can access blazer" do
    sign_in create(:user, :admin)

    get "/blazer"

    assert_not_equal "/users/sign_in", response.redirect_url
    assert_not_equal :not_found, response.status
  end
end
