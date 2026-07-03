require "test_helper"

class DataImportRunTest < ActiveSupport::TestCase
  test "invalid without data_artifact, schema_name, and schema_version" do
    run = DataImportRun.new

    assert_equal false, run.valid?
    assert_includes run.errors[:data_artifact], "must exist"
    assert_includes run.errors[:schema_name], "can't be blank"
    assert_includes run.errors[:schema_version], "can't be blank"
  end

  test "valid with data_artifact, schema_name, and schema_version" do
    run = build(:data_import_run)

    assert_equal true, run.valid?
  end

  test "defaults status and counters" do
    run = create(:data_import_run)

    assert_equal "pending", run.status
    assert_equal 0, run.records_seen
    assert_equal 0, run.records_imported
    assert_equal 0, run.records_failed
    assert_equal [], run.error_details
  end

  test "supports configured statuses" do
    run = create(:data_import_run)

    run.status_running!
    assert run.status_running?

    run.status_succeeded!
    assert run.status_succeeded?

    run.status_failed!
    assert run.status_failed?

    run.status_cancelled!
    assert run.status_cancelled?
  end

  test "supports aasm event-driven lifecycle. aasm hooks set timestamps." do
    run = create(:data_import_run)

    run.start_processing!
    assert run.status_running?
    assert_not_nil run.started_at

    run.mark_succeeded!
    assert run.status_succeeded?
    assert_not_nil run.finished_at
  end

  test "mark_failed appends error details. aasm hooks set finished_at." do
    run = create(:data_import_run)

    run.mark_failed!(RuntimeError.new("boom"))

    assert run.status_failed?
    assert_equal "RuntimeError", run.error_details.last["class"]
    assert_equal "boom", run.error_details.last["message"]
    assert_not_nil run.finished_at
  end
end
