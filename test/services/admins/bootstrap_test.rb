require "test_helper"

class AdminsBootstrapTest < ActiveSupport::TestCase
  setup do
    Admin.delete_all
  end

  teardown do
    Admin.delete_all
  end

  test "creates first admin when none exists" do
    result = Admins::Bootstrap.call(email: "ops@example.com", password: "a_secure_password_with_20_chars")

    assert_equal "created", result.fetch(:status)
    assert_equal "ops@example.com", result.fetch(:email)
    assert_equal 1, Admin.count
  end

  test "is idempotent when same admin exists" do
    Admin.create!(email: "ops@example.com", password: "a_secure_password_with_20_chars", password_confirmation: "a_secure_password_with_20_chars")

    result = Admins::Bootstrap.call(email: "ops@example.com", password: "a_different_secure_password_123")

    assert_equal "already_exists", result.fetch(:status)
    assert_equal "ops@example.com", result.fetch(:email)
    assert_equal "This command only bootstraps the first admin. Provision additional admins separately.", result.fetch(:message)
    assert_equal 1, Admin.count
  end

  test "raises when different admin exists" do
    Admin.create!(email: "existing@example.com", password: "a_secure_password_with_20_chars", password_confirmation: "a_secure_password_with_20_chars")

    error = assert_raises(Admins::Bootstrap::Error) do
      Admins::Bootstrap.call(email: "ops@example.com", password: "a_secure_password_with_20_chars")
    end

    assert_equal "An administrator already exists with a different email. This command only bootstraps the first admin. Provision additional admins separately.", error.message
    assert_equal 1, Admin.count
  end

  test "raises when email is blank" do
    error = assert_raises(Admins::Bootstrap::Error) do
      Admins::Bootstrap.call(email: "", password: "a_secure_password_with_20_chars")
    end

    assert_equal "ADMIN_EMAIL cannot be blank", error.message
  end

  test "raises when password is too short" do
    error = assert_raises(Admins::Bootstrap::Error) do
      Admins::Bootstrap.call(email: "ops@example.com", password: "short")
    end

    assert_equal "ADMIN_PASSWORD must be at least 20 characters. Admin password requires extra safety.", error.message
  end
end
