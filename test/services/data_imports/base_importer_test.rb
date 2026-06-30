require "test_helper"

module DataImports
  class BaseImporterTest < ActiveSupport::TestCase
    test "raises not implemented by default" do
      artifact = DataArtifact.create!(artifact_id: "artifact-base-importer-1", schema_name: "customer_accounts")
      run = DataImportRun.create!(
        data_artifact: artifact,
        schema_name: "customer_accounts",
        schema_version: "v1"
      )

      error = assert_raises(NotImplementedError) do
        BaseImporter.call(run: run)
      end

      assert_includes error.message, "must implement #call"
    end
  end
end
