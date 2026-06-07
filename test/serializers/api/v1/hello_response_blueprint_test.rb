require "test_helper"

module Api
  module V1
    class HelloResponseBlueprintTest < ActiveSupport::TestCase
      test "renders standardized hello response shape" do
        payload = {
          success: true,
          request_id: "req-123",
          message: "Hello, world!",
          cached: false,
          ignored_test_field: "i am not serialized"
        }

        serialized = HelloResponseBlueprint.render_as_hash(payload)

        assert_equal(
          {
            success: true,
            request_id: "req-123",
            message: "Hello, world!",
            cached: false
          },
          serialized
        )
      end
    end
  end
end
