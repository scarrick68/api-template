# test/integration/admin_tools_access_test.rb

require "test_helper"

module AdminToolsAccessTest
  class PgheroAccessTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers
    include ApiAuthHelpers

    test "anonymous users are redirected to sign in when trying to access pghero" do
      get "/pghero"

      assert_redirected_to "/admins/sign_in"
    end

    test "non-admin users are redirected to sign in when trying to access pghero" do
      sign_in create(:user)

      get "/pghero"

      assert_redirected_to "/admins/sign_in"
    end

    test "admin users can access pghero" do
      sign_in create(:user, :admin)

      get "/pghero"

      assert_not_equal "/admins/sign_in", response.redirect_url
      assert_not_equal :not_found, response.status
    end

    test "token-authenticated admin is still redirected for pghero" do
      admin_user = create(:user, :admin)

      get "/pghero", headers: auth_headers_for(admin_user)

      assert_redirected_to "/admins/sign_in"
    end
  end

  class BlazerAccessTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers
    include ApiAuthHelpers

    test "anonymous users are redirected to sign in when trying to access blazer" do
      get "/blazer"

      assert_redirected_to "/admins/sign_in"
    end

    test "non-admin users are redirected to sign in when trying to access blazer" do
      sign_in create(:user)

      get "/blazer"

      assert_redirected_to "/admins/sign_in"
    end

    test "admin users can access blazer" do
      sign_in create(:user, :admin)

      get "/blazer"

      assert_not_equal "/admins/sign_in", response.redirect_url
      assert_not_equal :not_found, response.status
    end

    test "token-authenticated admin is still redirected for blazer" do
      admin_user = create(:user, :admin)

      get "/blazer", headers: auth_headers_for(admin_user)

      assert_redirected_to "/admins/sign_in"
    end
  end

  class MissionControlJobsAccessTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers
    include ApiAuthHelpers

    test "anonymous users are redirected to sign in when trying to access mission control jobs" do
      get "/jobs"

      assert_redirected_to "/admins/sign_in"
    end

    test "non-admin users are redirected to sign in when trying to access mission control jobs" do
      sign_in create(:user)

      get "/jobs"

      assert_redirected_to "/admins/sign_in"
    end

    test "admin users pass app-level admin gate for mission control jobs" do
      sign_in create(:user, :admin)

      get "/jobs"

      assert_not_equal "/admins/sign_in", response.redirect_url
      assert_not_equal :not_found, response.status
    end

    test "token-authenticated admin is still redirected for mission control jobs" do
      admin_user = create(:user, :admin)

      get "/jobs", headers: auth_headers_for(admin_user)

      assert_redirected_to "/admins/sign_in"
    end
  end

  class SolidErrorsAccessTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers
    include ApiAuthHelpers

    test "anonymous users are redirected to sign in when trying to access solid errors" do
      get "/solid_errors"

      assert_redirected_to "/admins/sign_in"
    end

    test "non-admin users are redirected to sign in when trying to access solid errors" do
      sign_in create(:user)

      get "/solid_errors"

      assert_redirected_to "/admins/sign_in"
    end

    test "admin users pass app-level admin gate for solid errors" do
      sign_in create(:user, :admin)

      get "/solid_errors"

      assert_not_equal "/admins/sign_in", response.redirect_url
      assert_not_equal :not_found, response.status
    end

    test "token-authenticated admin is still redirected for solid errors" do
      admin_user = create(:user, :admin)

      get "/solid_errors", headers: auth_headers_for(admin_user)

      assert_redirected_to "/admins/sign_in"
    end
  end

  class FieldTestAccessTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers
    include ApiAuthHelpers

    test "anonymous users are redirected to sign in when trying to access field test" do
      get "/field_test"

      assert_redirected_to "/admins/sign_in"
    end

    test "non-admin users are redirected to sign in when trying to access field test" do
      sign_in create(:user)

      get "/field_test"

      assert_redirected_to "/admins/sign_in"
    end

    test "admin users pass app-level admin gate for field test" do
      sign_in create(:user, :admin)

      get "/field_test"

      assert_not_equal "/admins/sign_in", response.redirect_url
      assert_not_equal :not_found, response.status
    end

    test "token-authenticated admin is still redirected for field test" do
      admin_user = create(:user, :admin)

      get "/field_test", headers: auth_headers_for(admin_user)

      assert_redirected_to "/admins/sign_in"
    end
  end

  class FlipperAccessTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers
    include ApiAuthHelpers

    test "anonymous users are redirected to sign in when trying to access flipper" do
      get "/flipper"

      assert_redirected_to "/admins/sign_in"
    end

    test "non-admin users are redirected to sign in when trying to access flipper" do
      sign_in create(:user)

      get "/flipper"

      assert_redirected_to "/admins/sign_in"
    end

    test "admin users pass app-level admin gate for flipper" do
      sign_in create(:user, :admin)

      get "/flipper"

      assert_not_equal "/admins/sign_in", response.redirect_url
      assert_not_equal :not_found, response.status
    end

    test "token-authenticated admin is still redirected for flipper" do
      admin_user = create(:user, :admin)

      get "/flipper", headers: auth_headers_for(admin_user)

      assert_redirected_to "/admins/sign_in"
    end
  end

  class SearchjoyAccessTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers
    include ApiAuthHelpers

    test "anonymous users are redirected to sign in when trying to access searchjoy" do
      get "/searchjoy"

      assert_redirected_to "/admins/sign_in"
    end

    test "non-admin users are redirected to sign in when trying to access searchjoy" do
      sign_in create(:user)

      get "/searchjoy"

      assert_redirected_to "/admins/sign_in"
    end

    test "admin users pass app-level admin gate for searchjoy" do
      sign_in create(:user, :admin)

      get "/searchjoy"

      assert_not_equal "/admins/sign_in", response.redirect_url
      assert_not_equal :not_found, response.status
    end

    test "token-authenticated admin is still redirected for searchjoy" do
      admin_user = create(:user, :admin)

      get "/searchjoy", headers: auth_headers_for(admin_user)

      assert_redirected_to "/admins/sign_in"
    end
  end
end
