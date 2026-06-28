require "test_helper"

class AppEventTest < ActiveSupport::TestCase
  test "build returns structured payload hash" do
    payload = AppEvent.send(:build,
      "user.signup",
      severity: "INFO",
      user_id: 42,
      plan: "pro"
    )

    assert_equal "INFO", payload[:severity]
    assert_equal "user.signup", payload[:event]
    assert_equal 42, payload[:user_id]
    assert_equal "pro", payload[:plan]
    assert payload[:timestamp].present?
  end

  test "info logs structured json" do
    Rails.logger.expects(:info).with do |message|
      payload = JSON.parse(message)

      assert_equal "INFO", payload["severity"]
      assert_equal "user.signup", payload["event"]
      assert_equal 42, payload["user_id"]

      true
    end

    AppEvent.info("user.signup", user_id: 42)
  end

  test "warn logs structured json" do
    Rails.logger.expects(:warn).with do |message|
      payload = JSON.parse(message)

      assert_equal "WARN", payload["severity"]
      assert_equal "payment.retry", payload["event"]

      true
    end

    AppEvent.warn("payment.retry")
  end

  test "error logs structured json" do
    Rails.logger.expects(:error).with do |message|
      payload = JSON.parse(message)

      assert_equal "ERROR", payload["severity"]
      assert_equal "payment.failed", payload["event"]
      assert_equal 123, payload["order_id"]

      true
    end

    AppEvent.error("payment.failed", order_id: 123)
  end
end
