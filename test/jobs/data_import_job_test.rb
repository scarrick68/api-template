require "test_helper"

class DataImportJobTest < ActiveJob::TestCase
  include ActiveJob::TestHelper

  setup do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  test "marks data import run succeeded when importer finishes" do
    artifact = DataArtifact.create!(artifact_id: "artifact-job-1", schema_name: "test_schema_name")
    data_import_run = DataImportRun.create!(
      data_artifact: artifact,
      schema_name: "test_schema_name",
      schema_version: "v1"
    )

    importer_class = Class.new do
      class << self
        attr_accessor :called_data_import_run_id

        def call(data_import_run:)
          self.called_data_import_run_id = data_import_run.id
        end
      end
    end

    DataImports::Registry.stubs(:fetch).returns(importer_class)

    begin
      perform_enqueued_jobs do
        DataImportJob.perform_later(data_import_run.id)
      end
    ensure
      DataImports::Registry.unstub(:fetch)
    end

    data_import_run.reload

    assert_equal "succeeded", data_import_run.status
    assert_not_nil data_import_run.started_at
    assert_not_nil data_import_run.finished_at
    assert_equal data_import_run.id, importer_class.called_data_import_run_id
  end

  test "marks data import run failed once after retries are exhausted" do
    artifact = DataArtifact.create!(artifact_id: "artifact-job-2", schema_name: "test_schema_name")
    data_import_run = DataImportRun.create!(
      data_artifact: artifact,
      schema_name: "test_schema_name",
      schema_version: "v1",
      error_details: [ { "class" => "ExistingError", "message" => "already here" } ]
    )

    importer_class = Class.new do
      class << self
        attr_accessor :statuses
      end

      self.statuses = []

      def self.call(data_import_run:)
        self.statuses << data_import_run.reload.status
        raise StandardError, "import exploded"
      end
    end

    DataImports::Registry.stubs(:fetch).returns(importer_class)

    begin
      perform_enqueued_jobs do
        DataImportJob.perform_later(data_import_run.id)
      end
    ensure
      DataImports::Registry.unstub(:fetch)
    end

    data_import_run.reload

    assert_equal "failed", data_import_run.status
    assert_not_nil data_import_run.started_at
    assert_not_nil data_import_run.finished_at
    assert_equal 2, data_import_run.error_details.size
    assert_equal "ExistingError", data_import_run.error_details.first["class"]
    assert_equal "StandardError", data_import_run.error_details.last["class"]
    assert_equal "import exploded", data_import_run.error_details.last["message"]
    assert_equal Array.new(DataImportJob::RETRY_ATTEMPTS, "running"), importer_class.statuses
  end
end
