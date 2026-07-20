require "test_helper"
require "rake"

class LocalProdTaskTest < ActiveSupport::TestCase
  SETUP_TASK = "local_prod:setup_env"
  LIST_TASK = "local_prod:list_databases"

  setup do
    Rails.application.load_tasks unless Rake::Task.task_defined?(SETUP_TASK)
    setup_task.reenable
    list_task.reenable
  end

  test "setup task delegates to local prod env setup" do
    setup = mock("env_setup")
    LocalProd::EnvSetup.expects(:new).with(root_path: Rails.root.to_s).returns(setup)
    setup.expects(:ensure_env_file!).returns(true)

    setup_task.invoke
  end

  test "setup task aborts when env setup raises setup error" do
    setup = mock("env_setup")
    LocalProd::EnvSetup.expects(:new).with(root_path: Rails.root.to_s).returns(setup)
    setup.expects(:ensure_env_file!).raises(StandardError, "catalog unavailable")

    _stdout, stderr = capture_io do
      error = assert_raises(SystemExit) { setup_task.invoke }
      assert_equal 1, error.status
    end

    assert_includes stderr, "catalog unavailable"
  end

  test "list task prints diagnostics and existing databases" do
    setup = mock("env_setup")
    LocalProd::EnvSetup.expects(:new).with(root_path: Rails.root.to_s).returns(setup)
    setup.expects(:database_diagnostics).returns(
      {
        "development_configured" => "api_template_development",
        "production_configured" => "api_template_production",
        "inferred_from_development" => "api_template_development",
        "selected_database" => "api_template_development",
        "existing_databases" => [ "postgres", "api_template_development", "api_template_production" ]
      }
    )

    stdout, stderr = capture_io do
      list_task.invoke
    end

    assert_empty stderr
    assert_includes stdout, "development configured: api_template_development"
    assert_includes stdout, "production configured:  api_template_production"
    assert_includes stdout, "selected for env file:  api_template_development"
    assert_includes stdout, "- api_template_development"
  end

  test "list task aborts when diagnostics raise setup error" do
    setup = mock("env_setup")
    LocalProd::EnvSetup.expects(:new).with(root_path: Rails.root.to_s).returns(setup)
    setup.expects(:database_diagnostics).raises(StandardError, "catalog lookup failed")

    _stdout, stderr = capture_io do
      error = assert_raises(SystemExit) { list_task.invoke }
      assert_equal 1, error.status
    end

    assert_includes stderr, "catalog lookup failed"
  end

  test "list task can query live postgres catalog without stubs" do
    db_config = ActiveRecord::Base.connection_db_config
    skip "postgresql adapter required" unless db_config&.adapter == "postgresql"

    stdout, stderr = capture_io do
      list_task.invoke
    end

    assert_empty stderr
    assert_includes stdout, "existing databases:"
    assert_match(/^-\s+\S+/m, stdout)
  end

  private

  def setup_task
    Rake::Task[SETUP_TASK]
  end

  def list_task
    Rake::Task[LIST_TASK]
  end
end
