require "test_helper"

class DataArtifactTest < ActiveSupport::TestCase
  test "invalid without artifact_id and schema_name" do
    artifact = DataArtifact.new

    assert_equal false, artifact.valid?
    assert_includes artifact.errors[:artifact_id], "can't be blank"
    assert_includes artifact.errors[:schema_name], "can't be blank"
  end

  test "valid with artifact_id and schema_name" do
    artifact = DataArtifact.new(artifact_id: "some-model-data-csv", schema_name: "some_model")

    assert_equal true, artifact.valid?
  end

  test "defaults status to pending" do
    artifact = DataArtifact.create!(artifact_id: "some-model-data-csv", schema_name: "some_model")

    assert_equal "pending", artifact.status
  end

  test "supports configured statuses" do
    artifact = DataArtifact.create!(artifact_id: "some-model-data-csv", schema_name: "some_model")

    artifact.status_valid!
    assert artifact.status_valid?

    artifact.status_invalid!
    assert artifact.status_invalid?

    artifact.status_imported!
    assert artifact.status_imported?
  end

  test "ready_for_import? is true when record is valid and schema_version is present" do
    artifact = DataArtifact.new(
      artifact_id: "some-model-data-csv",
      schema_name: "some_model",
      schema_version: "v1"
    )

    assert_equal true, artifact.ready_for_import?
  end

  test "ready_for_import? is false when schema_version is missing" do
    artifact = DataArtifact.new(
      artifact_id: "some-model-data-csv",
      schema_name: "some_model",
      schema_version: nil
    )

    assert_equal false, artifact.ready_for_import?
  end
end
