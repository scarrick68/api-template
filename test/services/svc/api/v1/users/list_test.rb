require "test_helper"

module Svc
  module Api
    module V1
      module Users
        class ListTest < ActiveSupport::TestCase
          test "returns users ordered by created_at desc" do
            older = create(:user, email: "older@example.com", created_at: 2.days.ago)
            newer = create(:user, email: "newer@example.com", created_at: 1.day.ago)
            scope = User.where(id: [ older.id, newer.id ])

            result = List.call(scope: scope)

            assert_equal [ newer.id, older.id ], result.pluck(:id)
          end

          test "excludes soft deleted users" do
            active_user = create(:user, email: "active@example.com")
            deleted_user = create(:user, email: "deleted@example.com", deleted_at: Time.current)

            result = List.call(scope: User.where(id: [ active_user.id, deleted_user.id ]))

            assert_equal [ active_user.id ], result.pluck(:id)
          end
        end
      end
    end
  end
end
