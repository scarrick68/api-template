require "test_helper"
require "stringio"

module DataImports
  class ManifestReaderTest < ActiveSupport::TestCase
    test "reads, parses, and validates attached manifest json" do
      artifact = DataArtifact.create!(artifact_id: "artifact-reader-1", schema_name: "test_fixture_schema")
      manifest_json = {
        artifact_id: "artifact-reader-1",
        schema_name: "test_fixture_schema",
        schema_version: "v1",
        record_count: 2,
        created_at: Time.current.iso8601
      }.to_json

      artifact.file.attach(
        io: StringIO.new(manifest_json),
        filename: "manifest.json",
        content_type: "application/json"
      )

      result = ManifestReader.call(artifact:)

      assert result.success?
      assert_equal "test_fixture_schema", result.manifest[:schema_name]

      artifact.reload
      assert_equal "valid", artifact.status
      assert_equal [], artifact.metadata["manifest_validation_errors"]
    end

    test "stores invalid status and errors when attached manifest is not valid json" do
      artifact = DataArtifact.create!(artifact_id: "artifact-reader-2", schema_name: "test_fixture_schema")
      artifact.file.attach(
        io: StringIO.new("{not valid json"),
        filename: "manifest.json",
        content_type: "application/json"
      )

      result = ManifestReader.call(artifact:)

      assert_equal false, result.success?
      assert_includes result.errors, "Manifest file is not valid JSON"

      artifact.reload
      assert_equal "invalid", artifact.status
      assert_includes artifact.metadata["manifest_validation_errors"], "Manifest file is not valid JSON"
    end

    test "stores invalid status and errors when no file is attached" do
      artifact = DataArtifact.create!(artifact_id: "artifact-reader-3", schema_name: "test_fixture_schema")

      result = ManifestReader.call(artifact:)

      assert_equal false, result.success?
      assert_includes result.errors, "Manifest file is not attached"

      artifact.reload
      assert_equal "invalid", artifact.status
      assert_includes artifact.metadata["manifest_validation_errors"], "Manifest file is not attached"
    end
  end
end
