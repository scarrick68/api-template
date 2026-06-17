require "test_helper"

class AdminSessionsTest < ActionDispatch::IntegrationTest
  test "renders admin sign in page" do
    get "/admins/sign_in"

    assert_response :success
  end

  test "session login succeeds for confirmed admin and can sign out" do
    admin = create(:admin, email: unique_admin_email)

    post "/admins/sign_in", params: {
      admin: {
        email: admin.email,
        password: admin.password
      }
    }

    assert_response :redirect
    assert_not_includes response.headers["Location"].to_s, "/admins/sign_in"

    delete "/admins/sign_out"

    assert_response :redirect
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

  private

  def unique_admin_email
    "session-admin-#{SecureRandom.hex(6)}@example.com"
  end
end
