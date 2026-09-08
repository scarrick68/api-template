require "test_helper"

module Api
  module V1
    class FeaturesApiTest < ApplicationDispatchTest
      test "index requires authentication" do
        get "/api/v1/features"

        assert_response :unauthorized
        assert_conform_response_schema(401)
      end

      test "index returns effective feature flags for current user" do
        signed_in_user = create(:user, email: "feature-flags@example.com")
        other_user = create(:user, email: "feature-flags-other@example.com")

        actor_enabled_feature = "mobile_new_dashboard_#{SecureRandom.hex(4)}"
        globally_enabled_feature = "mobile_kill_switch_#{SecureRandom.hex(4)}"
        disabled_feature = "mobile_advanced_search_#{SecureRandom.hex(4)}"

        begin
          Flipper.add(actor_enabled_feature)
          Flipper.add(globally_enabled_feature)
          Flipper.add(disabled_feature)

          Flipper.enable_actor(actor_enabled_feature, signed_in_user)
          Flipper.enable(globally_enabled_feature)

          get "/api/v1/features", headers: auth_headers_for(signed_in_user)

          assert_response :success
          assert_conform_response_schema(200)
          assert_equal true, response.parsed_body["success"]

          flags = response.parsed_body["data"]
          assert_equal true, flags[actor_enabled_feature]
          assert_equal true, flags[globally_enabled_feature]
          assert_equal false, flags[disabled_feature]

          get "/api/v1/features", headers: auth_headers_for(other_user)

          assert_response :success
          assert_conform_response_schema(200)

          other_flags = response.parsed_body["data"]
          assert_equal false, other_flags[actor_enabled_feature]
          assert_equal true, other_flags[globally_enabled_feature]
          assert_equal false, other_flags[disabled_feature]
        ensure
          Flipper.remove(actor_enabled_feature)
          Flipper.remove(globally_enabled_feature)
          Flipper.remove(disabled_feature)
        end
      end
    end
  end
end
