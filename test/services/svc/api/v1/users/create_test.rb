require "test_helper"

module Svc
  module Api
    module V1
      module Users
        class CreateTest < ActiveSupport::TestCase
          test "creates and returns a user" do
            result = Create.call(
              attributes: {
                name: "Created User",
                email: "created-user@example.com",
                password: "password123",
                password_confirmation: "password123"
              }
            )

            assert_not_nil result.id
            assert_equal "Created User", result.name
            assert_equal "created-user@example.com", result.email
          end

          test "raises when model validation fails" do
            error = assert_raises(ActiveRecord::RecordInvalid) do
              Create.call(
                attributes: {
                  email: "",
                  password: "password123",
                  password_confirmation: "password123"
                }
              )
            end

            assert_includes error.record.errors.full_messages, "Email can't be blank"
          end

          test "raises when email already exists" do
            create(:user, email: "existing@example.com")

            error = assert_raises(ActiveRecord::RecordInvalid) do
              Create.call(
                attributes: {
                  name: "Another User",
                  email: "existing@example.com",
                  password: "password123",
                  password_confirmation: "password123"
                }
              )
            end

            assert_includes error.record.errors.full_messages, "Email has already been taken"
          end

          test "raises when email exists on soft-deleted user" do
            create(:user, email: "deleted-existing@example.com", deleted_at: Time.current)

            error = assert_raises(ActiveRecord::RecordInvalid) do
              Create.call(
                attributes: {
                  name: "Another User",
                  email: "deleted-existing@example.com",
                  password: "password123",
                  password_confirmation: "password123"
                }
              )
            end

            assert_includes error.record.errors.full_messages, "Email has already been taken"
          end
        end
      end
    end
  end
end
