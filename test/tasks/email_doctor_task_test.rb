require "test_helper"
require "rake"

class EmailDoctorTaskTest < ActiveSupport::TestCase
  TASK_NAME = "email:doctor"
  LAUNCH_READY_TASK_NAME = "email:doctor:launch_ready"

  setup do
    Rails.application.load_tasks unless Rake::Task.task_defined?(TASK_NAME)
    task.reenable
    launch_ready_task.reenable
  end

  test "prints warning report in normal mode without exiting" do
    Email::DoctorCheck.stubs(:new).with(launch_ready: false).returns(
      stub(call: result_with_warning)
    )

    stdout, stderr = capture_io do
      task.invoke
    end

    assert_includes stdout, "Email delivery"
    assert_includes stdout, "WARN: Action Mailer is using test delivery mode"
    assert_empty stderr
  end

  test "launch-ready task exits when failures are present" do
    Email::DoctorCheck.stubs(:new).with(launch_ready: true).returns(
      stub(call: result_with_failure)
    )

    stdout, stderr = capture_io do
      error = assert_raises(SystemExit) do
        launch_ready_task.invoke
      end

      assert_equal 1, error.status
    end

    assert_includes stdout, "FAIL: Action Mailer is using test delivery mode"
    assert_includes stderr, "Email doctor failed launch-readiness checks"
  end

  private

  def task
    Rake::Task[TASK_NAME]
  end

  def launch_ready_task
    Rake::Task[LAUNCH_READY_TASK_NAME]
  end

  def result_with_warning
    Email::DoctorCheck::Result.new(
      launch_ready: false,
      delivery_method: :test,
      perform_deliveries: true,
      raise_delivery_errors: false,
      mailer_host: "app.example.com",
      issues: [
        Email::DoctorCheck::Issue.new(
          :warning,
          "Action Mailer is using test delivery mode. External email delivery is disabled."
        )
      ]
    )
  end

  def result_with_failure
    Email::DoctorCheck::Result.new(
      launch_ready: true,
      delivery_method: :test,
      perform_deliveries: true,
      raise_delivery_errors: false,
      mailer_host: "app.example.com",
      issues: [
        Email::DoctorCheck::Issue.new(
          :failure,
          "Action Mailer is using test delivery mode. External email delivery is disabled."
        )
      ]
    )
  end
end
