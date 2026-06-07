require "test_helper"

module Api
  module V1
    module Hello
      class ShowContractTest < ActiveSupport::TestCase
        test "validate! passes for blank name" do
          contract = ShowContract.new(name: "")

          assert_equal contract, contract.validate!
        end

        test "validate! passes for valid name" do
          contract = ShowContract.new(name: "Ada")

          assert_equal contract, contract.validate!
        end

        test "validate! raises invalid when name exceeds max length" do
          contract = ShowContract.new(name: "a" * 51)

          error = assert_raises(ApplicationContract::Invalid) do
            contract.validate!
          end

          assert_includes error.errors, "Name is too long (maximum is 50 characters)"
        end
      end
    end
  end
end
