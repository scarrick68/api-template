require "test_helper"

class HelloWorldPolicyTest < ActiveSupport::TestCase
  test "show is allowed" do
    policy = HelloWorldPolicy.new(nil, Object.new)

    assert_equal true, policy.show?
  end

  test "create, update, and destroy remain denied by default" do
    policy = HelloWorldPolicy.new(nil, Object.new)

    assert_equal false, policy.create?
    assert_equal false, policy.update?
    assert_equal false, policy.destroy?
  end
end
