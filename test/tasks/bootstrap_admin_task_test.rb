require "test_helper"
require "rake"
require "json"

class BootstrapAdminTaskTest < ActiveSupport::TestCase
  TASK_NAME = "app:bootstrap_admin"

  setup do
    Rails.application.load_tasks unless Rake::Task.task_defined?(TASK_NAME)
  end

  teardown do
    Rake::Task[TASK_NAME].reenable
  end

  test "prints prefixed json result from service" do
    Admins::Bootstrap.expects(:call)
      .with(email: "ops@example.com", password: "a_secure_password_with_20_chars")
      .returns({ status: "created", email: "ops@example.com" })

    with_env("ADMIN_EMAIL" => "ops@example.com", "ADMIN_PASSWORD" => "a_secure_password_with_20_chars") do
      output = capture_io { task.invoke }.first
      result = parse_task_result(output)

      assert_equal "created", result.fetch("status")
      assert_equal "ops@example.com", result.fetch("email")
    end
  end

  test "aborts with service error message" do
    Admins::Bootstrap.expects(:call)
      .with(email: "ops@example.com", password: "a_secure_password_with_20_chars")
      .raises(Admins::Bootstrap::Error, "service failed")

    with_env("ADMIN_EMAIL" => "ops@example.com", "ADMIN_PASSWORD" => "a_secure_password_with_20_chars") do
      _stdout, stderr = capture_io do
        error = assert_raises(SystemExit) { task.invoke }
        assert_equal 1, error.status
      end

      assert_includes stderr, "service failed"
    end
  end

  private

  def task
    Rake::Task[TASK_NAME]
  end

  def with_env(values)
    originals = {}
    values.each_key { |key| originals[key] = ENV[key] }

    values.each { |key, value| ENV[key] = value }
    yield
  ensure
    originals.each do |key, value|
      if value.nil?
        ENV.delete(key)
      else
        ENV[key] = value
      end
    end
  end

  def parse_task_result(output)
    line = output.lines.find { |candidate| candidate.start_with?("ADMIN_BOOTSTRAP_RESULT=") }
    assert line, "Expected ADMIN_BOOTSTRAP_RESULT output line"

    JSON.parse(line.delete_prefix("ADMIN_BOOTSTRAP_RESULT="))
  end
end
