require "test_helper"
require "support/application_dispatch_test"

class AhoyTrackingTest < ApplicationDispatchTest
  setup do
    Ahoy.track_bots = true
  end

  teardown do
    Ahoy.track_bots = false
  end

  test "/me endpoint tracks an ahoy event" do
    signed_in_user = create(:user)

    assert_difference "Ahoy::Event.count", 1 do
      get me_api_v1_users_path, headers: auth_headers_for(signed_in_user)
    end
  end
end
