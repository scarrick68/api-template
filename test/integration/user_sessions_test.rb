require "test_helper"

class UserSessionsTest < ActionDispatch::IntegrationTest
  test "renders user sign in page" do
    get "/users/sign_in"

    assert_response :success
  end

  test "session login succeeds for confirmed user and can sign out" do
    user = User.create!(
      email: unique_email,
      password: "password123",
      password_confirmation: "password123",
      confirmed_at: Time.current
    )

    post "/users/sign_in", params: {
      user: {
        email: user.email,
        password: "password123"
      }
    }

    assert_response :redirect
    assert_not_includes response.headers["Location"].to_s, "/users/sign_in"

    delete "/users/sign_out"

    assert_response :redirect
  end

  test "session login is rejected for unconfirmed user" do
    user = User.create!(
      email: unique_email,
      password: "password123",
      password_confirmation: "password123"
    )

    post "/users/sign_in", params: {
      user: {
        email: user.email,
        password: "password123"
      }
    }

    assert_response :redirect
    assert_includes response.headers["Location"].to_s, "/users/sign_in"
  end

  private

  def unique_email
    "session-user-#{SecureRandom.hex(6)}@example.com"
  end
end
