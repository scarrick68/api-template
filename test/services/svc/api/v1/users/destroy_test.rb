require "test_helper"

module Svc
  module Api
    module V1
      module Users
        class DestroyTest < ActiveSupport::TestCase
          test "soft deletes user and returns deleted record" do
            user = create(:user)

            result = Destroy.call(user: user)

            assert_equal user.id, result.id
            deleted_user = User.unscoped.find_by(id: user.id)

            assert_not_nil deleted_user
            assert_not_nil deleted_user.deleted_at
          end

          test "is idempotent for an already soft deleted user" do
            user = create(:user, deleted_at: 1.minute.ago)
            deleted_at_before = user.deleted_at

            result = Destroy.call(user: user)

            assert_equal user.id, result.id

            user.reload

            assert_equal deleted_at_before.to_f, user.deleted_at.to_f
          end
        end
      end
    end
  end
end
