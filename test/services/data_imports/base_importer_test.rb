require "test_helper"

module DataImports
  class BaseImporterTest < ActiveSupport::TestCase
    test "raises not implemented by default" do
      artifact = DataArtifact.create!(artifact_id: "artifact-base-importer-1", schema_name: "test_schema_name")
      data_import_run = DataImportRun.create!(
        data_artifact: artifact,
        schema_name: "test_schema_name",
        schema_version: "v1"
      )

      error = assert_raises(NotImplementedError) do
        BaseImporter.call(data_import_run: data_import_run)
      end

      assert_includes error.message, "must implement #perform_import"
    end

    test "dry run wraps importer in rollback transaction by default" do
      artifact = DataArtifact.create!(artifact_id: "artifact-base-importer-2", schema_name: "test_schema_name")
      data_import_run = DataImportRun.create!(
        data_artifact: artifact,
        schema_name: "test_schema_name",
        schema_version: "v1",
        mode: "dry_run"
      )

      importer_class = Class.new(BaseImporter) do
        class << self
          attr_accessor :row_id
        end

        def perform_import
          metric = Metric.create!(
            name: "observability.test.import.dry_run",
            metric_type: "counter",
            value: 1,
            occurred_at: Time.current,
            labels: {},
            properties: {}
          )

          self.class.row_id = metric.id
        end
      end

      assert_no_difference -> { Metric.count } do
        importer_class.call(data_import_run: data_import_run)
      end

      refute_nil importer_class.row_id
      assert_nil Metric.find_by(id: importer_class.row_id)
    end

    test "import mode persists writes" do
      artifact = DataArtifact.create!(artifact_id: "artifact-base-importer-3", schema_name: "test_schema_name")
      data_import_run = DataImportRun.create!(
        data_artifact: artifact,
        schema_name: "test_schema_name",
        schema_version: "v1",
        mode: "import"
      )

      importer_class = Class.new(BaseImporter) do
        def perform_import
          Metric.create!(
            name: "observability.test.import.full",
            metric_type: "counter",
            value: 1,
            occurred_at: Time.current,
            labels: {},
            properties: {}
          )
        end
      end

      assert_difference -> { Metric.count }, 1 do
        importer_class.call(data_import_run: data_import_run)
      end
    end

    test "persist_enabled? is false for dry_run and true for import" do
      artifact = DataArtifact.create!(artifact_id: "artifact-base-importer-4", schema_name: "test_schema_name")

      dry_run = DataImportRun.create!(
        data_artifact: artifact,
        schema_name: "test_schema_name",
        schema_version: "v1",
        mode: "dry_run"
      )

      import_run = DataImportRun.create!(
        data_artifact: artifact,
        schema_name: "test_schema_name",
        schema_version: "v1",
        mode: "import"
      )

      importer_class = Class.new(BaseImporter) do
        def dry_run_strategy
          :validate_only
        end

        def perform_import
          {
            dry_run: dry_run?,
            import_mode: import_mode?,
            persist_enabled: persist_enabled?
          }
        end
      end

      dry_result = importer_class.call(data_import_run: dry_run)
      import_result = importer_class.call(data_import_run: import_run)

      assert_equal true, dry_result[:dry_run]
      assert_equal false, dry_result[:import_mode]
      assert_equal false, dry_result[:persist_enabled]

      assert_equal false, import_result[:dry_run]
      assert_equal true, import_result[:import_mode]
      assert_equal true, import_result[:persist_enabled]
    end
  end
end
