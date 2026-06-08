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
        end
      end
    end
  end
end
