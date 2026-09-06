# frozen_string_literal: true

require "test_helper"

# Test-only notifier used to verify provider-free Noticed behavior.
class TestOnlyNotifier < ApplicationNotifier
  notification_methods do
    def message
      params[:message]
    end
  end
end

class NoticedNotifierIntegrationTest < ActiveSupport::TestCase
  test "delivers and persists a database notification" do
    user = create(:user)

    assert_difference("Noticed::Event.count", 1) do
      assert_difference("Noticed::Notification.count", 1) do
        TestOnlyNotifier.with(message: "Hello").deliver(user)
      end
    end

    notification = user.notifications.order(:created_at).last
    assert_equal user, notification.recipient
    assert_equal "Hello", notification.message
    assert_equal "Hello", notification.event.params[:message]
  end

  test "delivers without external provider configuration" do
    user = create(:user)

    assert_nothing_raised do
      TestOnlyNotifier.with(message: "Provider free").deliver(user)
    end
  end
end
