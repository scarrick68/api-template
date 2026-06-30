require "test_helper"

class DataImportJobTest < ActiveJob::TestCase
  test "marks run succeeded when importer finishes" do
    artifact = DataArtifact.create!(artifact_id: "artifact-job-1", schema_name: "customer_accounts")
    run = DataImportRun.create!(
      data_artifact: artifact,
      schema_name: "customer_accounts",
      schema_version: "v1"
    )

    importer_class = Class.new do
      class << self
        attr_accessor :called_run_id

        def call(run:)
          self.called_run_id = run.id
        end
      end
    end

    DataImports::Registry.stubs(:fetch).returns(importer_class)

    begin
      DataImportJob.perform_now(run.id)
    ensure
      DataImports::Registry.unstub(:fetch)
    end

    run.reload

    assert_equal "succeeded", run.status
    assert_not_nil run.started_at
    assert_not_nil run.finished_at
    assert_equal run.id, importer_class.called_run_id
  end

  test "marks run failed and appends error details when importer raises" do
    artifact = DataArtifact.create!(artifact_id: "artifact-job-2", schema_name: "customer_accounts")
    run = DataImportRun.create!(
      data_artifact: artifact,
      schema_name: "customer_accounts",
      schema_version: "v1",
      error_details: [ { "class" => "ExistingError", "message" => "already here" } ]
    )

    importer_class = Class.new do
      def self.call(run:)
        raise StandardError, "import exploded"
      end
    end

    DataImports::Registry.stubs(:fetch).returns(importer_class)

    assert_raises(StandardError) do
      begin
        DataImportJob.perform_now(run.id)
      ensure
        DataImports::Registry.unstub(:fetch)
      end
    end

    run.reload

    assert_equal "failed", run.status
    assert_not_nil run.started_at
    assert_not_nil run.finished_at
    assert_equal 2, run.error_details.size
    assert_equal "ExistingError", run.error_details.first["class"]
    assert_equal "StandardError", run.error_details.last["class"]
    assert_equal "import exploded", run.error_details.last["message"]
  end
end
