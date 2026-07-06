require "test_helper"
require "rake"

class OpenSearchHealthTaskTest < ActiveSupport::TestCase
  TASK_NAME = "searchkick:health"

  setup do
    Rails.application.load_tasks unless Rake::Task.task_defined?(TASK_NAME)
    task.reenable
  end

  test "prints cluster and version when opensearch is healthy" do
    Searchkick.client.stubs(:info).returns(
      {
        "cluster_name" => "test-cluster",
        "version" => { "number" => "9.4.2" }
      }
    )

    stdout, stderr = capture_io do
      task.invoke
    end

    assert_includes stdout, "OpenSearch is healthy"
    assert_includes stdout, "Cluster: test-cluster"
    assert_includes stdout, "Version: 9.4.2"
    assert_empty stderr
  end

  test "prints error details and exits with status 1 when health check fails" do
    Searchkick.client.stubs(:info).raises(StandardError.new("connection refused"))

    stdout, stderr = capture_io do
      error = assert_raises(SystemExit) do
        task.invoke
      end

      assert_equal 1, error.status
    end

    assert_empty stdout
    assert_includes stderr, "OpenSearch health check failed"
    assert_includes stderr, "StandardError: connection refused"
  end

  private

  def task
    Rake::Task[TASK_NAME]
  end
end
