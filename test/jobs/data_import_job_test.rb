require "test_helper"

class DataImportJobTest < ActiveJob::TestCase
  test "marks data import run succeeded when importer finishes" do
    data_import_run = create(:data_import_run)

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
      DataImportJob.perform_now(data_import_run.id)
    ensure
      DataImports::Registry.unstub(:fetch)
    end

    data_import_run.reload

    assert_equal "succeeded", data_import_run.status
    assert_not_nil data_import_run.started_at
    assert_not_nil data_import_run.finished_at
    assert_equal data_import_run.id, importer_class.called_data_import_run_id
  end

  test "mark_failed! appends terminal error and marks data import run failed" do
    data_import_run = create(:data_import_run,
      status: :running,
      started_at: Time.current,
      error_details: [ { "class" => "ExistingError", "message" => "already here" } ]
    )

    DataImportJob.mark_failed!(data_import_run.id, StandardError.new("import exploded"))

    data_import_run.reload

    assert_equal "failed", data_import_run.status
    assert_not_nil data_import_run.started_at
    assert_not_nil data_import_run.finished_at
    assert_equal 2, data_import_run.error_details.size
    assert_equal "ExistingError", data_import_run.error_details.first["class"]
    assert_equal "StandardError", data_import_run.error_details.last["class"]
    assert_equal "import exploded", data_import_run.error_details.last["message"]
  end
end
