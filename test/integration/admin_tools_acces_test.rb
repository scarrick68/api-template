# test/integration/admin_tools_access_test.rb

require "test_helper"

class PgheroAccessTest < ActionDispatch::IntegrationTest
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
end

class BlazerAccessTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

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

class MissionControlJobsAccessTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "anonymous users are redirected to sign in when trying to access mission control jobs" do
    get "/jobs"

    assert_redirected_to "/users/sign_in"
  end

  test "non-admin users are redirected to sign in when trying to access mission control jobs" do
    sign_in create(:user)

    get "/jobs"

    assert_redirected_to "/users/sign_in"
  end

  test "admin users pass app-level admin gate for mission control jobs" do
    sign_in create(:user, :admin)

    get "/jobs"

    assert_not_equal "/users/sign_in", response.redirect_url
    assert_not_equal :not_found, response.status
  end
end

class SolidErrorsAccessTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "anonymous users are redirected to sign in when trying to access solid errors" do
    get "/solid_errors"

    assert_redirected_to "/users/sign_in"
  end

  test "non-admin users are redirected to sign in when trying to access solid errors" do
    sign_in create(:user)

    get "/solid_errors"

    assert_redirected_to "/users/sign_in"
  end

  test "admin users pass app-level admin gate for solid errors" do
    sign_in create(:user, :admin)

    get "/solid_errors"

    assert_not_equal "/users/sign_in", response.redirect_url
    assert_not_equal :not_found, response.status
  end
end
