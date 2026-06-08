require "test_helper"

module Api
  module V1
    module Users
      class CreateContractTest < ActiveSupport::TestCase
        test "validate! passes with valid attributes" do
          contract = CreateContract.new(
            name: "New User",
            email: "new-user@example.com",
            password: "password123",
            password_confirmation: "password123"
          )

          assert_equal contract, contract.validate!
          assert_equal "new-user@example.com", contract.email
        end

        test "validate! rejects mismatched password confirmation" do
          contract = CreateContract.new(
            email: "new-user@example.com",
            password: "password123",
            password_confirmation: "different"
          )

          error = assert_raises(ApplicationContract::Invalid) do
            contract.validate!
          end

          assert_includes error.errors, "Password confirmation must be equal to password"
        end
      end
    end
  end
end
