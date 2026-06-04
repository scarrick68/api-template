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
end
