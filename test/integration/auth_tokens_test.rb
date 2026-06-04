require "test_helper"

class AuthTokensTest < ActionDispatch::IntegrationTest
  TOKEN_HEADERS = ["access-token", "client", "uid", "expiry", "token-type"].freeze

  setup do
    ActionMailer::Base.deliveries.clear
  end

  test "sign up creates an unconfirmed account without auth token headers" do
    email = unique_email

    post "/auth", params: {
      email: email,
      password: "password123",
      password_confirmation: "password123",
      confirm_success_url: "http://localhost:3000/confirmed"
    }, as: :json

    assert_response :success
    assert_token_headers_absent

    user = User.find_by!(email: email)
    assert_nil user.confirmed_at
    assert user.confirmation_token.present?
  end

  test "login is rejected for unconfirmed user" do
    user = User.create!(
      email: unique_email,
      password: "password123",
      password_confirmation: "password123"
    )

    post "/auth/sign_in", params: {
      email: user.email,
      password: "password123"
    }, as: :json

    assert_response :unauthorized
    assert_token_headers_absent
  end

  test "login issues auth token headers for confirmed user" do
    user = User.create!(
      email: unique_email,
      password: "password123",
      password_confirmation: "password123",
      confirmed_at: Time.current
    )

    post "/auth/sign_in", params: {
      email: user.email,
      password: "password123"
    }, as: :json

    assert_response :success
    assert_auth_token_payload(user_email: user.email)
  end

  private

  def unique_email
    "user-#{SecureRandom.hex(6)}@example.com"
  end

  def assert_token_headers_present
    TOKEN_HEADERS.each do |header|
      assert response.headers[header].present?, "expected #{header} to be present"
    end
  end

  def assert_auth_token_payload(user_email:)
    assert_token_headers_present

    access_token = response.headers["access-token"]
    client = response.headers["client"]
    uid = response.headers["uid"]
    expiry = response.headers["expiry"]
    token_type = response.headers["token-type"]

    assert_match(/\A[\w\-]+\z/, access_token)
    assert_match(/\A[\w\-]+\z/, client)
    assert_equal user_email, uid
    assert_equal "Bearer", token_type
    assert_operator expiry.to_i, :>, Time.current.to_i
  end

  def assert_token_headers_absent
    TOKEN_HEADERS.each do |header|
      assert response.headers[header].blank?, "expected #{header} to be absent"
    end
  end
end
