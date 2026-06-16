require "test_helper"
require "securerandom"

class FlipperSmokeTest < ActiveSupport::TestCase
  test "flipper creates and toggles a persisted feature flag" do
    feature_key = "smoke_feature_#{SecureRandom.hex(6)}"

    begin
      Flipper.add(feature_key)

      assert Flipper.exist?(feature_key)
      assert_not Flipper.enabled?(feature_key)

      Flipper.enable(feature_key)
      assert Flipper.enabled?(feature_key)

      Flipper.disable(feature_key)
      assert_not Flipper.enabled?(feature_key)
      assert Flipper.exist?(feature_key)
    ensure
      Flipper.remove(feature_key)
    end
  end
end
