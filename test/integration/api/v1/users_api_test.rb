require "test_helper"
require "support/application_dispatch_test"

module Api
  module V1
    class UsersApiTest < ApplicationDispatchTest
      test "index requires authentication" do
        get "/api/v1/users"

        assert_response :unauthorized
      end

      test "index returns paginated users with metadata" do
        signed_in_user = create(:user, :admin, email: "signed-in@example.com")
        create(:user, email: "user-a@example.com")
        create(:user, email: "user-b@example.com")
        create(:user, email: "user-c@example.com")

        get "/api/v1/users",
            params: { page: 1, per_page: 2 },
            headers: auth_headers_for(signed_in_user)

        assert_response :success
        assert_equal true, response.parsed_body["success"]
        assert_equal response.headers["X-Request-Id"], response.parsed_body["request_id"]

        data = response.parsed_body["data"]
        meta = response.parsed_body["meta"]

        assert_equal 2, data.length
        assert_equal 1, meta["page"]
        assert_equal 2, meta["limit"]
      end

      test "index uses default pagination page size when page is omitted" do
        signed_in_user = create(:user, :admin, email: "signed-in2@example.com")
        create_list(:user, 3)

        get "/api/v1/users",
            params: { per_page: 2 },
            headers: auth_headers_for(signed_in_user)

        assert_response :success
        assert_equal 2, response.parsed_body["data"].length
        assert_equal 1, response.parsed_body["meta"]["page"]
        assert_equal 2, response.parsed_body["meta"]["limit"]
      end

      test "index is forbidden for non-admin authenticated users" do
        signed_in_user = create(:user, email: "signed-in3@example.com")

        get "/api/v1/users", headers: auth_headers_for(signed_in_user)

        assert_response :forbidden
        assert_equal false, response.parsed_body["success"]
        assert_equal "forbidden", response.parsed_body["error_type"]
      end

      test "show requires authentication" do
        user = create(:user)

        get "/api/v1/users/#{user.id}"

        assert_response :unauthorized
      end

      test "show returns user for admin" do
        signed_in_user = create(:user, :admin, email: "signed-in4@example.com")
        user_email = "show-user@example.com"
        user = create(:user, email: user_email, name: "Show User")

        get "/api/v1/users/#{user.id}", headers: auth_headers_for(signed_in_user)

        assert_response :success
        assert_equal true, response.parsed_body["success"]
        assert_equal response.headers["X-Request-Id"], response.parsed_body["request_id"]
        assert_equal user.id, response.parsed_body.dig("data", "id")
        assert_equal user_email, response.parsed_body.dig("data", "email")
      end

      test "show is allowed when non-admin authenticated users view self" do
        signed_in_user = create(:user, email: "signed-in5@example.com")

        get "/api/v1/users/#{signed_in_user.id}", headers: auth_headers_for(signed_in_user)

        assert_response :success
        assert_equal true, response.parsed_body["success"]
        assert_equal signed_in_user.id, response.parsed_body.dig("data", "id")
      end

      test "show is forbidden for non-admin authenticated users viewing others" do
        signed_in_user = create(:user, email: "signed-in5@example.com")
        other_user = create(:user)

        get "/api/v1/users/#{other_user.id}", headers: auth_headers_for(signed_in_user)

        assert_response :forbidden
        assert_equal false, response.parsed_body["success"]
        assert_equal "forbidden", response.parsed_body["error_type"]
      end

      test "show returns not found for missing user" do
        signed_in_user = create(:user, :admin, email: "signed-in6@example.com")

        get "/api/v1/users/999999", headers: auth_headers_for(signed_in_user)

        assert_response :not_found
        assert_equal false, response.parsed_body["success"]
        assert_equal "not_found", response.parsed_body["error_type"]
      end
    end
  end
end
