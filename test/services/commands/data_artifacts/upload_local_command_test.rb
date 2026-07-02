require "test_helper"
require "tempfile"
require Rails.root.join("lib/tasks/commands/data_artifacts/upload_local_command").to_s

module Commands
  module DataArtifacts
    class UploadLocalCommandTest < ActiveSupport::TestCase
      test "creates DataArtifact, attaches file, and stores basic metadata" do
        file = Tempfile.new([ "users", ".ndjson" ])
        file.write("{\"email\":\"upload-local@example.com\"}\n")
        file.flush

        artifact = UploadLocalCommand.call(
          file_path: file.path,
          schema_name: "users_ndjson",
          schema_version: "v1",
          source: "test_upload_local"
        )

        assert artifact.persisted?
        assert_equal "users_ndjson", artifact.schema_name
        assert_equal "v1", artifact.schema_version
        assert_equal "test_upload_local", artifact.source
        assert_equal "pending", artifact.status
        assert artifact.file.attached?
        assert_equal "rake", artifact.metadata["uploaded_via"]
        assert_not_nil artifact.byte_size
        assert_not_nil artifact.checksum
      ensure
        file&.close!
      end

      test "raises when file does not exist" do
        error = assert_raises(ArgumentError) do
          UploadLocalCommand.call(
            file_path: "tmp/does-not-exist.ndjson",
            schema_name: "users_ndjson"
          )
        end

        assert_includes error.message, "FILE not found"
      end
    end
  end
end
