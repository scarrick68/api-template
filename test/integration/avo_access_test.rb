require "test_helper"

class AvoAccessTest < ApplicationDispatchTest
  PROTECTED_AVO_PATHS = [
    "/avo",
    "/avo/resources/users"
  ].freeze

  test "anonymous users are redirected to sign in for avo routes" do
    PROTECTED_AVO_PATHS.each do |path|
      get path

      assert_redirected_to "/admins/sign_in"
    end
  end

  test "non-admin users are redirected to sign in for avo routes" do
    sign_in create(:user)
    PROTECTED_AVO_PATHS.each do |path|
      get path

      assert_redirected_to "/admins/sign_in"
    end
  end

  test "admin users can access avo" do
    sign_in create(:admin)

    get "/avo/resources/users"

    assert_not_equal "/admins/sign_in", response.redirect_url
    assert_not_equal :not_found, response.status
  end

  test "token-authenticated app user is still redirected for avo routes" do
    api_user = create(:user, :admin)

    PROTECTED_AVO_PATHS.each do |path|
      get path, headers: auth_headers_for(api_user)

      assert_redirected_to "/admins/sign_in"
    end
  end
end
