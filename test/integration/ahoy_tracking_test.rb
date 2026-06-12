require "test_helper"
require "support/application_dispatch_test"

class AhoyTrackingTest < ApplicationDispatchTest
  setup do
    Ahoy.track_bots = true

    Rails.application.routes.draw do
      get "/ahoy_tracking_test", to: "ahoy_tracking_test#show"
    end
  end

  teardown do
    Rails.application.reload_routes!
    Ahoy.track_bots = false
  end

  test "request tracking persists an ahoy event" do
    assert_difference "Ahoy::Event.count", 1 do
      get "/ahoy_tracking_test"
    end
  end
end

class AhoyTrackingTestController < ApplicationController
  def show
    ahoy.track "test.event"
    head :ok
  end
end
