require "test_helper"

module Svc
  module Api
    module V1
      module Users
        class UpdateTest < ActiveSupport::TestCase
          test "updates user attributes" do
            user = create(:user, name: "Before", email: "before@example.com")

            result = Update.call(user: user, attributes: { name: "After" })

            assert_equal user.id, result.id
            assert_equal "After", user.reload.name
            assert_equal "before@example.com", user.reload.email
          end

          test "is idempotent when attributes match existing values" do
            user = create(:user, name: "Stable Name", email: "stable@example.com")

            first = Update.call(user: user, attributes: { name: "Stable Name", email: "stable@example.com" })
            second = Update.call(user: user, attributes: { name: "Stable Name", email: "stable@example.com" })

            assert_equal first.id, second.id
            assert_equal "Stable Name", user.reload.name
            assert_equal "stable@example.com", user.reload.email
          end

          test "returns user unchanged when no attributes are provided" do
            user = create(:user, name: "No Change", email: "nochange@example.com")

            result = Update.call(user: user, attributes: {})

            assert_equal user.id, result.id
            assert_equal "No Change", user.reload.name
            assert_equal "nochange@example.com", user.reload.email
          end
        end
      end
    end
  end
end
