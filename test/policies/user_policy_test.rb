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
end
