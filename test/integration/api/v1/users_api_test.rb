require "test_helper"
require "support/application_dispatch_test"

module Api
  module V1
    class UsersIndexApiTest < ApplicationDispatchTest
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

      test "index excludes soft deleted users" do
        signed_in_user = create(:user, :admin, email: "signed-in18@example.com")
        active_user = create(:user, email: "index-active@example.com")
        deleted_user = create(:user, email: "index-deleted@example.com", deleted_at: Time.current)

        get "/api/v1/users", headers: auth_headers_for(signed_in_user)

        assert_response :success
        ids = response.parsed_body["data"].map { |row| row["id"] }
        assert_includes ids, active_user.id
        assert_not_includes ids, deleted_user.id
      end
    end

    class UsersShowApiTest < ApplicationDispatchTest
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

      test "show returns forbidden for missing user" do
        signed_in_user = create(:user, :admin, email: "signed-in6@example.com")

        get "/api/v1/users/999999", headers: auth_headers_for(signed_in_user)

        assert_response :forbidden
        assert_equal false, response.parsed_body["success"]
        assert_equal "forbidden", response.parsed_body["error_type"]
      end

      test "show returns soft deleted user for admin" do
        signed_in_user = create(:user, :admin, email: "signed-in17@example.com")
        deleted_user = create(:user, deleted_at: Time.current)

        get "/api/v1/users/#{deleted_user.id}", headers: auth_headers_for(signed_in_user)

        assert_response :success
        assert_equal true, response.parsed_body["success"]
        assert_equal deleted_user.id, response.parsed_body.dig("data", "id")
      end
    end

    class UsersUpdateApiTest < ApplicationDispatchTest
      test "update requires authentication" do
        user = create(:user)

        patch "/api/v1/users/#{user.id}", params: { name: "Updated Name" }

        assert_response :unauthorized
      end

      test "update allows admin to update another user" do
        signed_in_user = create(:user, :admin, email: "signed-in7@example.com")
        user = create(:user, email: "update-target@example.com", name: "Before Name")

        patch "/api/v1/users/#{user.id}",
              params: { name: "After Name" },
              headers: auth_headers_for(signed_in_user)

        assert_response :success
        assert_equal true, response.parsed_body["success"]
        assert_equal "After Name", response.parsed_body.dig("data", "name")
        assert_equal "After Name", user.reload.name
      end

      test "update allows non-admin users to update self" do
        signed_in_user = create(:user, email: "signed-in8@example.com", name: "Before Name")

        patch "/api/v1/users/#{signed_in_user.id}",
              params: { name: "After Name" },
              headers: auth_headers_for(signed_in_user)

        assert_response :success
        assert_equal true, response.parsed_body["success"]
        assert_equal "After Name", response.parsed_body.dig("data", "name")
        assert_equal "After Name", signed_in_user.reload.name
      end

      test "update is forbidden for non-admin users updating others" do
        signed_in_user = create(:user, email: "signed-in9@example.com")
        other_user = create(:user)

        patch "/api/v1/users/#{other_user.id}",
              params: { name: "Nope" },
              headers: auth_headers_for(signed_in_user)

        assert_response :forbidden
        assert_equal false, response.parsed_body["success"]
        assert_equal "forbidden", response.parsed_body["error_type"]
      end

      test "update returns forbidden for missing user" do
        signed_in_user = create(:user, :admin, email: "signed-in10@example.com")

        patch "/api/v1/users/999999",
              params: { name: "Missing" },
              headers: auth_headers_for(signed_in_user)

        assert_response :forbidden
        assert_equal false, response.parsed_body["success"]
        assert_equal "forbidden", response.parsed_body["error_type"]
      end

      test "update returns unprocessable entity for invalid email" do
        signed_in_user = create(:user, email: "signed-in11@example.com")

        patch "/api/v1/users/#{signed_in_user.id}",
              params: { email: "not-an-email" },
              headers: auth_headers_for(signed_in_user)

        assert_response :unprocessable_entity
        assert_equal false, response.parsed_body["success"]
        assert_equal "unprocessable_entity", response.parsed_body["error_type"]
      end

      test "update is idempotent for the same payload" do
        signed_in_user = create(:user, email: "signed-in12@example.com", name: "Stable Name")
        payload = { name: "Stable Name" }

        patch "/api/v1/users/#{signed_in_user.id}",
              params: payload,
              headers: auth_headers_for(signed_in_user)

        assert_response :success
        assert_equal "Stable Name", response.parsed_body.dig("data", "name")

        patch "/api/v1/users/#{signed_in_user.id}",
              params: payload,
              headers: auth_headers_for(signed_in_user)

        assert_response :success
        assert_equal "Stable Name", response.parsed_body.dig("data", "name")
        assert_equal "Stable Name", signed_in_user.reload.name
      end
    end

    class UsersDestroyApiTest < ApplicationDispatchTest
      test "destroy requires authentication" do
        user = create(:user)

        delete "/api/v1/users/#{user.id}"

        assert_response :unauthorized
      end

      test "destroy allows admin to delete another user" do
        signed_in_user = create(:user, :admin, email: "signed-in13@example.com")
        target_user = create(:user)

        delete "/api/v1/users/#{target_user.id}",
               headers: auth_headers_for(signed_in_user)

        assert_response :success
        assert_equal true, response.parsed_body["success"]
        assert_equal target_user.id, response.parsed_body.dig("data", "id")

        deleted_user = User.unscoped.find_by(id: target_user.id)
        assert_not_nil deleted_user
        assert_not_nil deleted_user.deleted_at
      end

      test "destroy allows non-admin users to delete self" do
        signed_in_user = create(:user, email: "signed-in14@example.com")
        user_id = signed_in_user.id

        delete "/api/v1/users/#{user_id}",
               headers: auth_headers_for(signed_in_user)

        assert_response :success
        assert_equal true, response.parsed_body["success"]
        assert_equal user_id, response.parsed_body.dig("data", "id")

        deleted_user = User.unscoped.find_by(id: user_id)
        assert_not_nil deleted_user
        assert_not_nil deleted_user.deleted_at
      end

      test "destroy is forbidden for non-admin users deleting others" do
        signed_in_user = create(:user, email: "signed-in15@example.com")
        target_user = create(:user)

        delete "/api/v1/users/#{target_user.id}",
               headers: auth_headers_for(signed_in_user)

        assert_response :forbidden
        assert_equal false, response.parsed_body["success"]
        assert_equal "forbidden", response.parsed_body["error_type"]
        assert_not_nil User.find_by(id: target_user.id)
      end

      test "destroy returns forbidden for missing user" do
        signed_in_user = create(:user, :admin, email: "signed-in16@example.com")

        delete "/api/v1/users/999999", headers: auth_headers_for(signed_in_user)

        assert_response :forbidden
        assert_equal false, response.parsed_body["success"]
        assert_equal "forbidden", response.parsed_body["error_type"]
      end
    end
  end
end
