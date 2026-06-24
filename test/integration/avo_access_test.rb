require "test_helper"

class AvoAccessTest < ApplicationDispatchTest
  setup do
    Avo::Licensing::HQ.any_instance.stubs(:response).returns({})
  end

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
    sign_in create(:user), scope: :user

    PROTECTED_AVO_PATHS.each do |path|
      get path

      assert_redirected_to "/admins/sign_in"
    end
  end

  test "authenticated admin users can access avo dashboard" do
    sign_in create(:admin), scope: :admin

    get "/avo"

    assert_redirected_to "/avo/resources/users"
  end

  test "authenticated admin users can access avo resources" do
    sign_in create(:admin), scope: :admin

    get "/avo/resources/users"

    assert_response :success
  end

  test "token-authenticated admin user is still redirected to session login for avo routes" do
    api_user = create(:user, :admin)

    PROTECTED_AVO_PATHS.each do |path|
      get path, headers: auth_headers_for(api_user)

      assert_redirected_to "/admins/sign_in"
    end
  end
end
