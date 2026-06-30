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
    artifact = DataArtifact.create!(artifact_id: "some-model-data-csv", schema_name: "some_model")
    run = DataImportRun.new(
      data_artifact: artifact,
      schema_name: "some_model",
      schema_version: "v1"
    )

    assert_equal true, run.valid?
  end

  test "defaults status and counters" do
    artifact = DataArtifact.create!(artifact_id: "artifact-3", schema_name: "restaurants")
    run = DataImportRun.create!(
      data_artifact: artifact,
      schema_name: "restaurants",
      schema_version: "v1"
    )

    assert_equal "pending", run.status
    assert_equal 0, run.records_seen
    assert_equal 0, run.records_imported
    assert_equal 0, run.records_failed
    assert_equal [], run.error_details
  end

  test "supports configured statuses" do
    artifact = DataArtifact.create!(artifact_id: "artifact-4", schema_name: "restaurants")
    run = DataImportRun.create!(
      data_artifact: artifact,
      schema_name: "restaurants",
      schema_version: "v1"
    )

    run.status_running!
    assert run.status_running?

    run.status_succeeded!
    assert run.status_succeeded?

    run.status_failed!
    assert run.status_failed?

    run.status_cancelled!
    assert run.status_cancelled?
  end
end
