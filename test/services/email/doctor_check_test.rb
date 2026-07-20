require "test_helper"
require "ostruct"

class Email::DoctorCheckTest < ActiveSupport::TestCase
  test "normal mode warns for test delivery" do
    check = Email::DoctorCheck.new(launch_ready: false)
    check.stubs(:mailer_config).returns(
      mailer_config(
        delivery_method: :test,
        perform_deliveries: true,
        raise_delivery_errors: false,
        default_url_options: { host: "app.example.com" },
        smtp_settings: {}
      )
    )
    check.stubs(:default_sender).returns("no-reply@example.com")

    result = check.call

    assert_equal false, result.failed?
    assert_equal 1, result.warnings.length
    assert_equal 0, result.failures.length
    assert_match(/test delivery mode/i, result.warnings.first.message)
  end

  test "launch-ready mode fails for test delivery" do
    check = Email::DoctorCheck.new(launch_ready: true)
    check.stubs(:mailer_config).returns(
      mailer_config(
        delivery_method: :test,
        perform_deliveries: true,
        raise_delivery_errors: false,
        default_url_options: { host: "app.example.com" },
        smtp_settings: {}
      )
    )
    check.stubs(:default_sender).returns("no-reply@example.com")

    result = check.call

    assert_equal true, result.failed?
    assert_equal 1, result.failures.length
    assert_match(/test delivery mode/i, result.failures.first.message)
  end

  test "launch-ready mode fails for smtp localhost host" do
    check = Email::DoctorCheck.new(launch_ready: true)
    check.stubs(:mailer_config).returns(
      mailer_config(
        delivery_method: :smtp,
        perform_deliveries: true,
        raise_delivery_errors: true,
        default_url_options: { host: "app.example.com" },
        smtp_settings: { address: "localhost" }
      )
    )
    check.stubs(:default_sender).returns("no-reply@example.com")

    result = check.call

    assert_equal true, result.failed?
    assert result.failures.any? { |issue| issue.message.match?(/localhost/) }
  end

  test "launch-ready mode passes for external smtp and host/sender present" do
    check = Email::DoctorCheck.new(launch_ready: true)
    check.stubs(:mailer_config).returns(
      mailer_config(
        delivery_method: :smtp,
        perform_deliveries: true,
        raise_delivery_errors: true,
        default_url_options: { host: "app.example.com" },
        smtp_settings: { address: "smtp.example.com" }
      )
    )
    check.stubs(:default_sender).returns("no-reply@example.com")

    result = check.call

    assert_equal false, result.failed?
    assert_empty result.issues
  end

  private

  def mailer_config(delivery_method:, perform_deliveries:, raise_delivery_errors:, default_url_options:, smtp_settings:)
    OpenStruct.new(
      delivery_method: delivery_method,
      perform_deliveries: perform_deliveries,
      raise_delivery_errors: raise_delivery_errors,
      default_url_options: default_url_options,
      smtp_settings: smtp_settings
    )
  end
end
