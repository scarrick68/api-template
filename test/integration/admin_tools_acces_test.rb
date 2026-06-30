require "test_helper"

module AdminToolsAccessTest
  class DashboardAccessTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers
    include ApiAuthHelpers

    test "anonymous users are redirected to sign in when trying to access admin tools dashboard" do
      get "/admin/tools"

      assert_redirected_to "/admins/sign_in"
    end

    test "non-admin users are redirected to sign in when trying to access admin tools dashboard" do
      sign_in create(:user)

      get "/admin/tools"

      assert_redirected_to "/admins/sign_in"
    end

    test "admin users can access admin tools dashboard" do
      sign_in create(:admin), scope: :admin

      get "/admin/tools"

      assert_response :success
      assert_includes response.body, "Admin Dashboard"
    end

    test "token-authenticated admin is still redirected to login when accessing admin tools dashboard" do
      admin_user = create(:user, :admin)

      get "/admin/tools", headers: auth_headers_for(admin_user)

      assert_redirected_to "/admins/sign_in"
    end
  end

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

    test "token-authenticated admin is still redirected to login when accessing pghero" do
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

    test "token-authenticated admin is still redirected to login when accessing blazer" do
      admin_user = create(:user, :admin)

      get "/blazer", headers: auth_headers_for(admin_user)

      assert_redirected_to "/admins/sign_in"
    end
  end

  class GoodJobAccessTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers
    include ApiAuthHelpers

    test "anonymous users are redirected to sign in when trying to access good job" do
      get "/good_job"

      assert_redirected_to "/admins/sign_in"
    end

    test "non-admin users are redirected to sign in when trying to access good job" do
      sign_in create(:user)

      get "/good_job"

      assert_redirected_to "/admins/sign_in"
    end

    test "admin users can access good job" do
      sign_in create(:admin), scope: :admin

      get "/good_job"

      assert_redirected_to "/good_job/jobs?locale=en"
    end

    test "token-authenticated admin is still redirected to login when accessing good job" do
      admin_user = create(:user, :admin)

      get "/good_job", headers: auth_headers_for(admin_user)

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

    test "token-authenticated admin is still redirected to login when accessing solid errors" do
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

    test "token-authenticated admin is still redirected to login when accessing field test" do
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

    test "token-authenticated admin is still redirected to login when accessing flipper" do
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

    test "token-authenticated admin is still redirected to login when accessing searchjoy" do
      admin_user = create(:user, :admin)

      get "/searchjoy", headers: auth_headers_for(admin_user)

      assert_redirected_to "/admins/sign_in"
    end
  end
end
