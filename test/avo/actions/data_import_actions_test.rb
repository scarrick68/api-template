require "test_helper"

class DataImportActionsTest < ActiveSupport::TestCase
  test "dry run action creates pending dry_run and enqueues job" do
    artifact = create(:data_artifact, artifact_id: "artifact-dry-run-1")

    action = Avo::Actions::DataArtifacts::DryRunImport.new

    DataImportJob.expects(:perform_later).once

    assert_difference -> { DataImportRun.count }, 1 do
      action.handle(query: [ artifact ])
    end

    data_import_run = DataImportRun.order(:id).last

    assert_equal artifact.id, data_import_run.data_artifact_id
    assert_equal "test_schema_name", data_import_run.schema_name
    assert_equal "v1", data_import_run.schema_version
    assert_equal "dry_run", data_import_run.mode
    assert_equal "pending", data_import_run.status
    assert_equal({ "attempt" => 1 }, data_import_run.options)
  end

  test "subsequent dry run actions create separate historical runs and increment attempt" do
    artifact = create(:data_artifact, artifact_id: "artifact-dry-run-history-1")

    action = Avo::Actions::DataArtifacts::DryRunImport.new

    DataImportJob.expects(:perform_later).twice

    assert_difference -> { DataImportRun.count }, 2 do
      action.handle(query: [ artifact ])
      action.handle(query: [ artifact ])
    end

    runs = DataImportRun.where(data_artifact: artifact).order(:id)

    assert_equal 2, runs.size
    assert_equal [ "dry_run", "dry_run" ], runs.map(&:mode)
    assert_equal [ 1, 2 ], runs.map { |run| run.options["attempt"] }
  end

  test "run import action creates pending import run and enqueues job" do
    artifact = create(:data_artifact, artifact_id: "artifact-import-1")

    action = Avo::Actions::DataArtifacts::RunImport.new

    DataImportJob.expects(:perform_later).once

    assert_difference -> { DataImportRun.count }, 1 do
      action.handle(query: [ artifact ])
    end

    data_import_run = DataImportRun.order(:id).last

    assert_equal "import", data_import_run.mode
    assert_equal "pending", data_import_run.status
    assert_equal({ "attempt" => 1 }, data_import_run.options)
  end

  test "subsequent import actions create separate historical runs and increment attempt" do
    artifact = create(:data_artifact, artifact_id: "artifact-import-history-1")

    action = Avo::Actions::DataArtifacts::RunImport.new

    DataImportJob.expects(:perform_later).twice

    assert_difference -> { DataImportRun.count }, 2 do
      action.handle(query: [ artifact ])
      action.handle(query: [ artifact ])
    end

    runs = DataImportRun.where(data_artifact: artifact).order(:id)

    assert_equal 2, runs.size
    assert_equal [ "import", "import" ], runs.map(&:mode)
    assert_equal [ 1, 2 ], runs.map { |run| run.options["attempt"] }
  end

  test "dry run followed by import starts each mode attempt at one" do
    artifact = create(:data_artifact, artifact_id: "artifact-mixed-modes-1")

    dry_run_action = Avo::Actions::DataArtifacts::DryRunImport.new
    run_import_action = Avo::Actions::DataArtifacts::RunImport.new

    DataImportJob.expects(:perform_later).twice

    assert_difference -> { DataImportRun.count }, 2 do
      dry_run_action.handle(query: [ artifact ])
      run_import_action.handle(query: [ artifact ])
    end

    dry_run = DataImportRun.where(data_artifact: artifact, mode: "dry_run").order(:id).last
    import_run = DataImportRun.where(data_artifact: artifact, mode: "import").order(:id).last

    assert_equal 1, dry_run.options["attempt"]
    assert_equal 1, import_run.options["attempt"]
  end

  test "retry action increments attempt for dry_run mode" do
    artifact = create(:data_artifact, artifact_id: "artifact-retry-1")

    previous_data_import_run = create(:data_import_run,
      data_artifact: artifact,
      mode: "dry_run",
      status: :failed,
      finished_at: Time.current,
      options: { "attempt" => 1 }
    )

    action = Avo::Actions::DataImportRuns::RetryImport.new

    DataImportJob.expects(:perform_later).once

    assert_difference -> { DataImportRun.count }, 1 do
      action.handle(query: [ previous_data_import_run ])
    end

    data_import_run = DataImportRun.order(:id).last

    assert_equal artifact.id, data_import_run.data_artifact_id
    assert_equal "test_schema_name", data_import_run.schema_name
    assert_equal "v1", data_import_run.schema_version
    assert_equal "dry_run", data_import_run.mode
    assert_equal "pending", data_import_run.status
    assert_equal(
      {
        "attempt" => 2,
        "retry_of_data_import_run_id" => previous_data_import_run.id
      },
      data_import_run.options
    )
  end

  test "retry action increments attempt for import mode" do
    artifact = create(:data_artifact, artifact_id: "artifact-retry-import-1")

    previous_data_import_run = create(:data_import_run,
      data_artifact: artifact,
      mode: "import",
      status: :failed,
      finished_at: Time.current,
      options: { "attempt" => 1 }
    )

    action = Avo::Actions::DataImportRuns::RetryImport.new

    DataImportJob.expects(:perform_later).once

    assert_difference -> { DataImportRun.count }, 1 do
      action.handle(query: [ previous_data_import_run ])
    end

    data_import_run = DataImportRun.order(:id).last

    assert_equal "import", data_import_run.mode
    assert_equal(
      {
        "attempt" => 2,
        "retry_of_data_import_run_id" => previous_data_import_run.id
      },
      data_import_run.options
    )
  end

  test "retry action does not enqueue retry for a run that is still running" do
    artifact = create(:data_artifact, artifact_id: "artifact-retry-running-1")

    previous_data_import_run = create(:data_import_run,
      data_artifact: artifact,
      mode: "dry_run",
      status: :running,
      started_at: Time.current,
      options: { "attempt" => 1 }
    )

    action = Avo::Actions::DataImportRuns::RetryImport.new

    DataImportJob.expects(:perform_later).never

    assert_no_difference -> { DataImportRun.count } do
      error = assert_raises(RuntimeError) do
        action.handle(query: [ previous_data_import_run ])
      end

      assert_includes error.message, "Retry cannot be created because a run is currently in progress"
      assert_includes error.message, "Wait for the run to finish and try again"
    end
  end

  test "retry action does not enqueue duplicate retry while prior retry is pending" do
    artifact = create(:data_artifact, artifact_id: "artifact-retry-duplicate-1")

    previous_data_import_run = create(:data_import_run,
      data_artifact: artifact,
      mode: "import",
      status: :failed,
      finished_at: Time.current,
      options: { "attempt" => 1 }
    )

    create(:data_import_run,
      data_artifact: artifact,
      mode: "import",
      status: :pending,
      options: { "retry_of_data_import_run_id" => previous_data_import_run.id }
    )

    action = Avo::Actions::DataImportRuns::RetryImport.new

    DataImportJob.expects(:perform_later).never

    assert_no_difference -> { DataImportRun.count } do
      error = assert_raises(RuntimeError) do
        action.handle(query: [ previous_data_import_run ])
      end

      assert_includes error.message, "Retry cannot be created because a run is currently in progress"
      assert_includes error.message, "Wait for the run to finish and try again"
    end
  end
end
