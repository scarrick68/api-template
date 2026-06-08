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
        end
      end
    end
  end
end
