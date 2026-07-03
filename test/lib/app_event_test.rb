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

  test "redacts sensitive top-level payload fields" do
    Rails.logger.expects(:info).with do |message|
      payload = JSON.parse(message)

      assert_equal "[FILTERED]", payload["password"]
      assert_equal "[FILTERED]", payload["access_token"]
      assert_equal "[FILTERED]", payload["secret"]
      assert_equal "visible stuff here", payload["note"]

      true
    end

    AppEvent.info(
      "security.audit",
      password: "super-secret",
      access_token: "abc123",
      secret: "s3cr3t",
      note: "visible stuff here"
    )
  end

  test "redacts nested sensitive payload fields" do
    Rails.logger.expects(:warn).with do |message|
      payload = JSON.parse(message)

      assert_equal "[FILTERED]", payload.dig("credentials", "password")
      assert_equal "[FILTERED]", payload.dig("credentials", "reset_token")
      assert_equal "[FILTERED]", payload.dig("actors", 0, "email")
      assert_equal "[FILTERED]", payload.dig("actors", 0, "otp")

      true
    end

    AppEvent.warn(
      "security.audit",
      credentials: {
        password: "super-secret",
        reset_token: "reset-abc"
      },
      actors: [
        {
          email: "private@example.com",
          otp: "123456"
        }
      ]
    )
  end
end
