require "test_helper"

module Api
  module V1
    class PushDevicesApiTest < ApplicationDispatchTest
      test "create requires authentication" do
        post "/api/v1/push_devices", params: {
          push_token: "ExponentPushToken[token-1]"
        }, as: :json

        assert_response :unauthorized
        assert_conform_response_schema(401)
      end

      test "create upserts push registration for authenticated user" do
        user = create(:user)

        assert_difference("PushDevice.count", 1) do
          post "/api/v1/push_devices", params: {
            push_token: "ExponentPushToken[token-1]",
            platform: "iOS",
            app_version: "1.4.0",
            build_version: "42"
          }, headers: auth_headers_for(user), as: :json
        end

        assert_response :accepted
        assert_conform_response_schema(202)

        record = PushDevice.find_by!(push_token: "ExponentPushToken[token-1]")
        assert_equal user.id, record.user_id
        assert_equal "ios", record.platform
        assert_equal true, record.active
        assert_equal "1.4.0", record.app_version
        assert_equal "42", record.build_version

        travel 1.second do
          assert_no_difference("PushDevice.count") do
            post "/api/v1/push_devices", params: {
              push_token: "ExponentPushToken[token-1]",
              platform: "android"
            }, headers: auth_headers_for(user), as: :json
          end

          assert_response :accepted
          assert_conform_response_schema(202)

          record.reload
          assert_equal "android", record.platform
          assert_equal true, record.active
          assert_operator record.last_registered_at, :>, 1.second.ago
        end
      end

      test "create can transfer token ownership to current user" do
        old_user = create(:user)
        new_user = create(:user)
        record = create(:push_device, user: old_user, push_token: "ExponentPushToken[token-transfer]", platform: "ios", active: false)

        post "/api/v1/push_devices", params: {
          push_token: record.push_token,
          platform: "web"
        }, headers: auth_headers_for(new_user), as: :json

        assert_response :accepted
        assert_conform_response_schema(202)

        record.reload
        assert_equal new_user.id, record.user_id
        assert_equal "web", record.platform
        assert_equal true, record.active
      end

      test "create returns bad request when token missing" do
        user = create(:user)

        post "/api/v1/push_devices", params: {
          platform: "ios"
        }, headers: auth_headers_for(user), as: :json

        assert_response :bad_request
        assert_conform_response_schema(400)
      end

      test "destroy requires authentication" do
        delete "/api/v1/push_devices", params: { push_token: "ExponentPushToken[token-1]" }, as: :json

        assert_response :unauthorized
        assert_conform_response_schema(401)
      end

      test "destroy deactivates only current user token" do
        user = create(:user)
        other_user = create(:user)
        own_device = create(:push_device, user: user, push_token: "ExponentPushToken[token-1]", active: true)
        _other_device = create(:push_device, user: other_user, push_token: "ExponentPushToken[token-2]", active: true)

        delete "/api/v1/push_devices", params: {
          push_token: own_device.push_token
        }, headers: auth_headers_for(user), as: :json

        assert_response :accepted
        assert_conform_response_schema(202)

        assert_equal false, own_device.reload.active
        assert_equal true, PushDevice.find_by!(push_token: "ExponentPushToken[token-2]").active
      end

      test "destroy does not deactivate another user's token" do
        user = create(:user)
        other_user = create(:user)
        other_device = create(:push_device, user: other_user, push_token: "ExponentPushToken[token-foreign]", active: true)

        delete "/api/v1/push_devices", params: {
          push_token: other_device.push_token
        }, headers: auth_headers_for(user), as: :json

        assert_response :forbidden
        assert_conform_response_schema(403)

        assert_equal true, other_device.reload.active
      end
    end
  end
end
