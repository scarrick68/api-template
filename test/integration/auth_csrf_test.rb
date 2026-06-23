require "test_helper"

class AuthCsrfTest < ActionDispatch::IntegrationTest
  setup do
    ActionController::Base.stubs(:allow_forgery_protection).returns(true)
  end

  test "auth controllers use null-session forgery strategy" do
    auth_controllers.each do |controller|
      assert_equal null_session_strategy, controller.forgery_protection_strategy
    end
  end

  test "registration route is not blocked by missing CSRF token" do
    assert_difference "User.count", 1 do
      post "/auth",
        params: registration_params,
        headers: json_origin_headers,
        as: :json
    end

    assert_response :success
    assert_not_equal 422, response.status
  end

  test "session route is not blocked by missing CSRF token" do
    user = create_confirmed_user

    post "/auth/sign_in",
      params: sign_in_params(user),
      headers: json_origin_headers,
      as: :json

    assert_response :success
    assert_not_equal 422, response.status
    assert_auth_headers_present
  end

  test "password reset route is not blocked by missing CSRF token" do
    user = create_confirmed_user

    post "/auth/password",
      params: {
        email: user.email,
        redirect_url: "http://localhost:3000/reset-password"
      },
      headers: json_origin_headers,
      as: :json

    assert_response :success
    assert_not_equal 422, response.status
  end

  test "application controller keeps exception forgery strategy for session auth'ed controllers / requests" do
    assert_equal exception_strategy, ApplicationController.forgery_protection_strategy
  end

  private

  def auth_controllers
    [
      Auth::RegistrationsController,
      Auth::SessionsController,
      Auth::PasswordsController
    ]
  end

  def null_session_strategy
    ActionController::RequestForgeryProtection::ProtectionMethods::NullSession
  end

  def exception_strategy
    ActionController::RequestForgeryProtection::ProtectionMethods::Exception
  end

  def registration_params
    {
      email: "csrf-#{SecureRandom.hex(6)}@example.com",
      password: password,
      password_confirmation: password,
      confirm_success_url: "http://localhost:3000/confirmed"
    }
  end

  def sign_in_params(user)
    {
      email: user.email,
      password: password
    }
  end

  def create_confirmed_user
    User.create!(
      email: "csrf-login-#{SecureRandom.hex(6)}@example.com",
      password: password,
      password_confirmation: password,
      confirmed_at: Time.current
    )
  end

  def json_origin_headers
    { "Origin" => "http://localhost:3000" }
  end

  def assert_auth_headers_present
    assert response.headers["access-token"].present?
    assert response.headers["client"].present?
    assert response.headers["uid"].present?
  end

  def password
    "password123"
  end
end