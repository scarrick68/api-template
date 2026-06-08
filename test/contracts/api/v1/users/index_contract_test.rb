require "test_helper"

module Api
  module V1
    module Users
      class IndexContractTest < ActiveSupport::TestCase
        test "validate! passes with defaults" do
          contract = IndexContract.new

          assert_equal contract, contract.validate!
          assert_equal 1, contract.page
          assert_equal 25, contract.per_page
        end

        test "validate! rejects page below minimum" do
          contract = IndexContract.new(page: 0)

          error = assert_raises(ApplicationContract::Invalid) do
            contract.validate!
          end

          assert_includes error.errors, "Page must be greater than 0"
        end

        test "validate! rejects per_page above max" do
          contract = IndexContract.new(per_page: 101)

          error = assert_raises(ApplicationContract::Invalid) do
            contract.validate!
          end

          assert_includes error.errors, "Per page must be less than or equal to 100"
        end
      end
    end
  end
end
