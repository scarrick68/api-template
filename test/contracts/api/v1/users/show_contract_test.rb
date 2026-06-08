require "test_helper"

module Api
  module V1
    module Users
      class ShowContractTest < ActiveSupport::TestCase
        test "validate! passes for positive id" do
          contract = ShowContract.new(id: 42)

          assert_equal contract, contract.validate!
          assert_equal 42, contract.id
        end

        test "validate! rejects missing id" do
          contract = ShowContract.new

          error = assert_raises(ApplicationContract::Invalid) do
            contract.validate!
          end

          assert_includes error.errors, "Id is not a number"
        end

        test "validate! rejects id below minimum" do
          contract = ShowContract.new(id: 0)

          error = assert_raises(ApplicationContract::Invalid) do
            contract.validate!
          end

          assert_includes error.errors, "Id must be greater than 0"
        end
      end
    end
  end
end
