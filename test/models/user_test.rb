require "test_helper"

class UserTest < ActiveSupport::TestCase
  def setup
    Searchkick.enable_callbacks
  end

  def teardown
    Searchkick.disable_callbacks
  end

  test "normalizes email before validation" do
    user = build(:user, email: "  MixedCase@Example.com  ")

    assert user.valid?
    assert_equal "mixedcase@example.com", user.email
  end

  test "rejects duplicate email when existing user is soft deleted" do
    create(:user, email: "taken@example.com", deleted_at: Time.current)
    user = build(:user, email: "taken@example.com")

    assert_equal false, user.valid?
    assert_includes user.errors.full_messages, "Email has already been taken"
  end

  test "rejects duplicate email case-insensitively" do
    create(:user, email: "taken@example.com")
    user = build(:user, email: "TAKEN@example.com")

    assert_equal false, user.valid?
    assert_includes user.errors.full_messages, "Email has already been taken"
  end

  test "searches by name" do
    user = create(:user, name: "Search User")
    User.search_index.refresh
    assert_equal [ user.name ], User.search(user.name).map(&:name)
  end

  test "has field test memberships association" do
    user = create(:user)
    membership = FieldTest::Membership.create!(
      experiment: "user_signup_flow",
      variant: "control",
      participant_type: "User",
      participant_id: user.id.to_s
    )

    assert_includes user.field_test_memberships, membership
  end
end
