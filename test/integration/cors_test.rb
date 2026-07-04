require "test_helper"

class CorsTest < ActionDispatch::IntegrationTest
  test "preflight request returns CORS headers for allowed origin" do
    origin = "http://localhost:3000"

    options "/up", headers: {
      "Origin" => origin,
      "Access-Control-Request-Method" => "GET"
    }

    assert_response :success
    assert_equal origin, response.headers["access-control-allow-origin"]
    assert_includes response.headers["access-control-allow-methods"], "GET"
  end

  test "simple request returns CORS allow-origin header for allowed origin" do
    origin = "http://localhost:3000"

    get "/up", headers: { "Origin" => origin }

    assert_response :success
    assert_equal origin, response.headers["access-control-allow-origin"]
  end

  test "request from non-whitelisted origin does not include CORS allow-origin header" do
    origin = "http://evil.example"

    get "/up", headers: { "Origin" => origin }

    assert_response :success
    assert_nil response.headers["access-control-allow-origin"]
  end

  test "cross-origin sign-in exposes DTA auth headers" do
    origin = "http://localhost:3000"
    user = create(:user)

    post "/auth/sign_in",
      params: {
        email: user.email,
        password: user.password
      },
      headers: { "Origin" => origin },
      as: :json

    assert_response :success
    assert_equal origin, response.headers["access-control-allow-origin"]

    exposed_headers = response.headers["access-control-expose-headers"].to_s.downcase
    %w[access-token client uid expiry token-type].each do |header_name|
      assert_includes exposed_headers, header_name
      assert response.headers[header_name].present?, "expected #{header_name} to be present"
    end
  end
end
