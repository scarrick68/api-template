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
end
