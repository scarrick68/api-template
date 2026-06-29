require "test_helper"
require "cgi"
require "uri"

class AuthTokensTest < ActionDispatch::IntegrationTest
  include ApiAuthHelpers

  PASSWORD_RESET_REDIRECT_URL = "http://www.example.com/reset-password".freeze
  TOKEN_HEADERS = [ "access-token", "client", "uid", "expiry", "token-type" ].freeze

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
    assert_conform_schema(200)
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
    assert_conform_schema(401)
    assert_token_headers_absent
    assert_equal false, response.parsed_body["success"]
    assert response.parsed_body["errors"].present?
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
    assert_conform_schema(200)
    assert_auth_token_payload(user_email: user.email)
  end

  test "validate token returns current user payload for active token" do
    user = User.create!(
      email: unique_email,
      password: "password123",
      password_confirmation: "password123",
      confirmed_at: Time.current
    )

    headers = auth_headers_for(user)

    get "/auth/validate_token", headers: headers, as: :json

    assert_response :success
    assert_conform_schema(200)
    assert_equal user.email, response.parsed_body.dig("data", "email")
  end

  test "validate token returns unauthorized for invalid token headers" do
    get "/auth/validate_token", headers: invalid_auth_headers, as: :json

    assert_response :unauthorized
    assert_conform_schema(401)
  end

  test "sign out succeeds for active token" do
    user = User.create!(
      email: unique_email,
      password: "password123",
      password_confirmation: "password123",
      confirmed_at: Time.current
    )

    headers = auth_headers_for(user)

    delete "/auth/sign_out", headers: headers, as: :json

    assert_response :success
    assert_conform_schema(200)
    assert_equal true, response.parsed_body["success"]
  end

  test "signed out token cannot be reused" do
    user = User.create!(
      email: unique_email,
      password: "password123",
      password_confirmation: "password123",
      confirmed_at: Time.current
    )

    stale_headers = auth_headers_for(user).dup

    delete "/auth/sign_out", headers: stale_headers, as: :json

    assert_response :success
    assert_conform_schema(200)

    travel 6.seconds do
      get "/auth/validate_token", headers: stale_headers, as: :json

      assert_response :unauthorized
      assert_conform_schema(401)
    end
  end

  test "sign out returns not found for invalid token" do
    delete "/auth/sign_out", headers: invalid_auth_headers, as: :json

    assert_response :not_found
    assert_conform_schema(404)
  end

  test "password reset invalidates previously issued auth token headers" do
    user = create(
      :user,
      email: unique_email,
      password: "password123",
      password_confirmation: "password123",
      confirmed_at: Time.current
    )

    stale_headers = auth_headers_for(user)

    # DTA compares token expiry timestamps; ensure the reset token is newer than the stale token.
    travel 2.seconds do
      reset_password_for(user, password: "new-password-123")
    end

    get "/auth/validate_token", headers: stale_headers, as: :json

    assert_response :unauthorized
    assert_conform_schema(401)
  end

  private

  def unique_email
    "user-#{SecureRandom.hex(6)}@example.com"
  end

  def invalid_auth_headers
    {
      "access-token" => "invalid-token",
      "client" => "invalid-client",
      "uid" => "invalid@example.com"
    }
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

  def reset_password_token_from_last_email
    email = ActionMailer::Base.deliveries.last
    assert_not_nil email, "expected a password reset email to be sent"

    reset_url = URI.extract(email.body.encoded).find do |url|
      url.include?("reset_password_token=")
    end

    assert_not_nil reset_url, "expected reset_password_token URL in password reset email"

    query_params(reset_url).fetch("reset_password_token")
  end

  def auth_headers_from_url(url)
    params = query_params(url)

    {
      "access-token" => params.fetch("access-token"),
      "client" => params.fetch("client"),
      "uid" => params.fetch("uid")
    }
  end

  def query_params(url)
    uri = URI.parse(url)
    Rack::Utils.parse_query(uri.query)
  end

  def reset_password_for(user, password:)
    post "/auth/password",
      params: {
        email: user.email,
        redirect_url: PASSWORD_RESET_REDIRECT_URL
      },
      as: :json

    assert_response :success

    get "/auth/password/edit",
      params: {
        reset_password_token: reset_password_token_from_last_email,
        redirect_url: PASSWORD_RESET_REDIRECT_URL
      },
      as: :json

    assert_response :redirect

    put "/auth/password",
      params: {
        password: password,
        password_confirmation: password
      },
      headers: auth_headers_from_url(response.redirect_url),
      as: :json

    assert_response :success
  end
end
