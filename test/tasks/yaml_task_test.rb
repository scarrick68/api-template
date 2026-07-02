require "test_helper"
require "rake"
require "tmpdir"

class YamlTaskTest < ActiveSupport::TestCase
  TASK_NAME = "yaml:lint"

  setup do
    Rails.application.load_tasks unless Rake::Task.task_defined?(TASK_NAME)
    task.reenable
  end

  test "prints success for valid yaml" do
    Dir.mktmpdir do |dir|
      file_path = File.join(dir, "valid.yml")
      File.write(file_path, "name: demo\nitems:\n  - a\n  - b\n")

      stdout, stderr = capture_io do
        task.invoke(file_path)
      end

      assert_includes stdout, "✓ #{file_path}"
      assert_empty stderr
    end
  end

  test "fails for invalid yaml" do
    Dir.mktmpdir do |dir|
      file_path = File.join(dir, "invalid.yml")
      File.write(file_path, "name: [broken\n")

      stdout, stderr = capture_io do
        error = assert_raises(SystemExit) do
          task.invoke(file_path)
        end

        assert_equal 1, error.status
      end

      assert_empty stdout
      assert_includes stderr, "✗ #{file_path}"
    end
  end

  private

  def task
    Rake::Task[TASK_NAME]
  end
end
