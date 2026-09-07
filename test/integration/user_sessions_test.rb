require "test_helper"

class AdminSessionsTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "renders admin sign in page" do
    get "/admins/sign_in"

    assert_response :success
  end

  test "admin can sign in with valid credentials" do
    password = "password123"

    admin = create(
      :admin,
      email: unique_admin_email,
      password: password,
      password_confirmation: password
    )

    post "/admins/sign_in", params: {
      admin: {
        email: admin.email,
        password: password
      }
    }

    assert_response :redirect
    assert_no_match %r{/admins/sign_in}, response.location.to_s
  end

  test "session login is rejected for invalid credentials" do
    admin = create(:admin, email: unique_admin_email)

    post "/admins/sign_in", params: {
      admin: {
        email: admin.email,
        password: "wrong-password"
      }
    }

    assert_response :success
    assert_includes response.body, "sign_in"
  end

  test "signed in admin can sign out" do
    admin = create(:admin)
    sign_in admin, scope: :admin

    delete "/admins/sign_out"

    assert_response :redirect
  end

  private

  def unique_admin_email
    "session-admin-#{SecureRandom.hex(6)}@example.com"
  end
end
