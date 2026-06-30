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

    artifact.status_validated!
    assert artifact.status_validated?

    artifact.status_invalid!
    assert artifact.status_invalid?

    artifact.status_imported!
    assert artifact.status_imported?
  end
end
