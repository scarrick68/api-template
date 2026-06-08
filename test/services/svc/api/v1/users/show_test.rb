require "test_helper"

module Svc
  module Api
    module V1
      module Users
        class ShowTest < ActiveSupport::TestCase
          test "returns user by id" do
            user = create(:user)

            result = Show.call(id: user.id)

            assert_equal user.id, result.id
          end

          test "returns nil for missing id" do
            assert_nil Show.call(id: 999999)
          end

          test "returns nil for soft deleted user" do
            user = create(:user, deleted_at: Time.current)

            assert_nil Show.call(id: user.id)
          end

          test "returns soft deleted user when scope is unscoped" do
            user = create(:user, deleted_at: Time.current)

            result = Show.call(id: user.id, scope: User.unscoped)

            assert_equal user.id, result.id
            assert_not_nil result.deleted_at
          end
        end
      end
    end
  end
end
