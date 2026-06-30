require "test_helper"

module DataImports
  class ManifestValidatorTest < ActiveSupport::TestCase
    test "returns normalized manifest for valid payload" do
      # schema_name identifies the data domain in the manifest contract.
      payload = {
        artifact_id: "customer-accounts-export-2026-06-29",
        schema_name: "customer_accounts",
        schema_version: "v1",
        record_count: 12,
        created_at: Time.current.iso8601,
        files: [
          {
            name: "customer_accounts.ndjson",
            checksum: "abc123",
            byte_size: 100
          }
        ]
      }

      result = ManifestValidator.call(payload:)

      assert result.success?
      assert_equal "customer_accounts", result.manifest[:schema_name]
      assert_equal "v1", result.manifest[:schema_version]
      assert_equal [], result.errors
    end

    test "stores validation errors on artifact when payload is invalid" do
      artifact = DataArtifact.create!(artifact_id: "artifact-validate-1", schema_name: "customer_accounts")

      result = ManifestValidator.call(payload: { schema_name: "customer_accounts" }, artifact:)

      assert_equal false, result.success?
      assert result.errors.any?

      artifact.reload
      assert_equal "invalid", artifact.status
      assert_equal result.errors, artifact.metadata["manifest_validation_errors"]
    end

    test "marks artifact validated and stores normalized manifest when payload is valid" do
      artifact = DataArtifact.create!(artifact_id: "artifact-validate-2", schema_name: "customer_accounts")
      payload = {
        artifact_id: "artifact-validate-2",
        schema_name: "customer_accounts",
        schema_version: "v1",
        record_count: 3,
        created_at: Time.current.iso8601
      }

      result = ManifestValidator.call(payload:, artifact:)

      assert result.success?

      artifact.reload
      assert_equal "validated", artifact.status
      assert_equal "customer_accounts", artifact.metadata.dig("manifest", "schema_name")
      assert_equal [], artifact.metadata["manifest_validation_errors"]
    end
  end
end
