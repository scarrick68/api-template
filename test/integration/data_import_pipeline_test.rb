require "test_helper"
require "rake"
require "stringio"
require "tempfile"

class DataImportPipelineTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    clear_enqueued_jobs
    clear_performed_jobs

    Rails.application.load_tasks unless Rake::Task.task_defined?("data_artifacts:upload_local")
    Rake::Task["data_artifacts:upload_local"].reenable
    Rake::Task["data_imports:start_run"].reenable if Rake::Task.task_defined?("data_imports:start_run")
  end

  test "smoke path: avo actions run dry_run then import for user ndjson" do
    artifact = upload_artifact_via_avo(
      ndjson_payload: user_ndjson("avo"),
      source: "smoke_avo",
      current_user: create(:admin)
    )

    importer_class = build_user_ndjson_importer
    DataImports::Registry.stubs(:fetch).returns(importer_class)

    begin
      perform_enqueued_jobs do
        Avo::Actions::DataArtifacts::DryRunImport.new.handle(query: [ artifact ])
        Avo::Actions::DataArtifacts::RunImport.new.handle(query: [ artifact ])
      end
    ensure
      DataImports::Registry.unstub(:fetch)
    end

    runs = DataImportRun.where(data_artifact: artifact).order(:id)
    dry_run = runs.find { |run| run.mode == "dry_run" }
    import_run = runs.find { |run| run.mode == "import" }

    assert_equal 2, runs.size
    assert_equal "succeeded", dry_run.status
    assert_equal "succeeded", import_run.status
    assert_equal 1, dry_run.options["attempt"]
    assert_equal 1, import_run.options["attempt"]
    assert_equal 2, import_run.records_seen
    assert_equal 2, import_run.records_imported

    assert_equal 1, User.where(email: "avo-import-1@example.com").count
    assert_equal 1, User.where(email: "avo-import-2@example.com").count
  end

  test "e2e smoke test: upload artifact and import users through rake entry points" do
    # Register a simple test importer so the full pipeline can execute.
    importer_class = build_user_ndjson_importer
    DataImports::Registry.stubs(:fetch).returns(importer_class)

    begin
      # Create a temporary NDJSON artifact that simulates a generated data file.
      file = Tempfile.new([ "users", ".ndjson" ])
      file.write(user_ndjson("script"))
      file.flush

      # Exercise the upload entry point exactly as a developer would from the CLI.
      Rake::Task["data_artifacts:upload_local"].invoke(
        file.path,
        "users_ndjson",
        "v1",
        "smoke_script"
      )

      artifact = DataArtifact
        .where(schema_name: "users_ndjson", source: "smoke_script")
        .order(:id)
        .last

      assert_not_nil artifact

      # Exercise the import entry point and run all background jobs synchronously.
      perform_enqueued_jobs do
        Rake::Task["data_imports:start_run"].invoke(artifact.id, "import")
      end
    ensure
      file&.close!
      DataImports::Registry.unstub(:fetch)

      # Rake tasks must be re-enabled before they can be invoked again.
      Rake::Task["data_artifacts:upload_local"].reenable
      Rake::Task["data_imports:start_run"].reenable
    end

    artifact = DataArtifact
      .where(schema_name: "users_ndjson", source: "smoke_script")
      .order(:id)
      .last

    run = DataImportRun.where(data_artifact: artifact).order(:id).last

    # Verify the import lifecycle completed successfully.
    assert_equal "succeeded", run.status
    assert_equal "import", run.mode
    assert_equal 1, run.options["attempt"]
    assert_equal 2, run.records_seen
    assert_equal 2, run.records_imported

    # Verify the importer persisted the expected records.
    assert_equal 1, User.where(email: "script-import-1@example.com").count
    assert_equal 1, User.where(email: "script-import-2@example.com").count
  end

  private

  def upload_artifact_via_avo(ndjson_payload:, source:, current_user:)
    file = Tempfile.new([ "users", ".ndjson" ])
    file.write(ndjson_payload)
    file.flush

    uploaded_file = ActionDispatch::Http::UploadedFile.new(
      tempfile: file,
      filename: "users.ndjson",
      type: "application/x-ndjson"
    )

    action = Avo::Actions::DataArtifacts::UploadArtifact.new
    action.handle(
      query: [],
      fields: {
        artifact_file: uploaded_file,
        schema_name: "users_ndjson",
        schema_version: "v1",
        source: source
      },
      current_user: current_user,
      resource: Avo::Resources::DataArtifact
    )

    DataArtifact.where(schema_name: "users_ndjson", source: source).order(:id).last
  ensure
    file&.close!
  end

  def user_ndjson(prefix)
    [
      {
        email: "#{prefix}-import-1@example.com",
        name: "#{prefix} Import User 1"
      },
      {
        email: "#{prefix}-import-2@example.com",
        name: "#{prefix} Import User 2"
      }
    ].map(&:to_json).join("\n") + "\n"
  end

  # Fake User importer for testing the data import pipeline end-to-end. This is not a real importer.
  def build_user_ndjson_importer
    Class.new(DataImports::BaseImporter) do
      def perform_import
        rows = data_import_run.data_artifact.file.download.lines.map(&:strip).reject(&:blank?).map { |line| JSON.parse(line) }

        records_seen = 0
        records_imported = 0
        records_failed = 0
        import_errors = []

        rows.each_with_index do |row, idx|
          records_seen += 1

          user = User.new(
            email: row.fetch("email"),
            name: row["name"],
            provider: "email",
            uid: row.fetch("email"),
            password: "password123",
            password_confirmation: "password123",
            confirmed_at: Time.current,
            confirmation_sent_at: Time.current
          )

          if user.save
            records_imported += 1
          else
            records_failed += 1
            import_errors << {
              "row" => idx + 1,
              "errors" => user.errors.full_messages
            }
          end
        end

        data_import_run.with_lock do
          data_import_run.reload
          data_import_run.update!(
            records_seen: data_import_run.records_seen + records_seen,
            records_imported: data_import_run.records_imported + records_imported,
            records_failed: data_import_run.records_failed + records_failed,
            error_details: Array(data_import_run.error_details) + import_errors
          )
        end
      end
    end
  end
end
