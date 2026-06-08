require "test_helper"

class UserPolicyTest < ActiveSupport::TestCase
  test "index is allowed for admins" do
    policy = UserPolicy.new(build(:user, :admin), User)

    assert_equal true, policy.index?
  end

  # This test assumes that the user is auth'ed when policy is checked,
  # but does not actually execute the auth flow.
  test "index is denied for authenticated non-admin users" do
    policy = UserPolicy.new(build(:user), User)

    assert_equal false, policy.index?
  end

  test "index is denied for guests" do
    policy = UserPolicy.new(nil, User)

    assert_equal false, policy.index?
  end

  test "show is allowed for admins" do
    policy = UserPolicy.new(build(:user, :admin), User)

    assert_equal true, policy.show?
  end

  test "show is allowed when user is viewing self" do
    current_user = build(:user)
    policy = UserPolicy.new(current_user, current_user)

    assert_equal true, policy.show?
  end

  test "show is denied for authenticated non-admin users viewing others" do
    policy = UserPolicy.new(build(:user), build(:user))

    assert_equal false, policy.show?
  end

  test "show is denied for guests" do
    policy = UserPolicy.new(nil, User)

    assert_equal false, policy.show?
  end

  test "update is allowed for admins" do
    policy = UserPolicy.new(build(:user, :admin), User)

    assert_equal true, policy.update?
  end

  test "update is allowed when user is updating self" do
    current_user = build(:user)
    policy = UserPolicy.new(current_user, current_user)

    assert_equal true, policy.update?
  end

  test "update is denied for authenticated non-admin users updating others" do
    policy = UserPolicy.new(build(:user), build(:user))

    assert_equal false, policy.update?
  end

  test "update is denied for guests" do
    policy = UserPolicy.new(nil, User)

    assert_equal false, policy.update?
  end
end
