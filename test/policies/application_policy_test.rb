require "test_helper"

class ApplicationPolicyTest < ActiveSupport::TestCase
  test "defaults to deny all common actions" do
    policy = ApplicationPolicy.new(nil, Object.new)

    assert_equal false, policy.index?
    assert_equal false, policy.show?
    assert_equal false, policy.create?
    assert_equal false, policy.update?
    assert_equal false, policy.destroy?
  end
end
