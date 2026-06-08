require "test_helper"

module Api
  module V1
    module Users
      class UpdateContractTest < ActiveSupport::TestCase
        test "validate! passes for id with partial attributes" do
          contract = UpdateContract.new(id: 42, name: "Updated")

          assert_equal contract, contract.validate!
          assert_equal 42, contract.id
          assert_equal "Updated", contract.name
        end

        test "validate! passes when only id is provided" do
          contract = UpdateContract.new(id: 42)

          assert_equal contract, contract.validate!
          assert_equal 42, contract.id
        end

        test "validate! rejects missing id" do
          contract = UpdateContract.new(name: "Updated")

          error = assert_raises(ApplicationContract::Invalid) do
            contract.validate!
          end

          assert_includes error.errors, "Id is not a number"
        end

        test "validate! rejects invalid email format" do
          contract = UpdateContract.new(id: 42, email: "invalid-email")

          error = assert_raises(ApplicationContract::Invalid) do
            contract.validate!
          end

          assert_includes error.errors, "Email is invalid"
        end
      end
    end
  end
end
