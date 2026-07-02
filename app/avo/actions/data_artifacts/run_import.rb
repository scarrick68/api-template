class Avo::Actions::DataArtifacts::RunImport < Avo::BaseAction
  self.name = "Data Artifacts/Run Import"
  self.message = "Create import runs for selected artifacts and enqueue DataImportJob."

  def handle(query:, **)
    enqueued = 0

    query.each do |artifact|
      next if artifact.schema_name.blank? || artifact.schema_version.blank?

      run = DataImportRun.create!(
        data_artifact: artifact,
        schema_name: artifact.schema_name,
        schema_version: artifact.schema_version,
        mode: "import",
        status: :pending,
        options: { "attempt" => next_import_attempt_for(artifact) }
      )

      DataImportJob.perform_later(run.id)
      enqueued += 1
    end

    if enqueued.zero?
      fail "No import runs were created. Ensure selected artifacts include schema_name and schema_version."
    else
      succeed "Created and enqueued #{enqueued} import run(s)."
    end
  rescue StandardError => e
    fail "Run import failed: #{e.message}"
  end

  private

  def next_import_attempt_for(artifact)
    prior_attempts = DataImportRun
      .where(
        data_artifact_id: artifact.id,
        schema_name: artifact.schema_name,
        schema_version: artifact.schema_version,
        mode: "import"
      )
      .pluck(:options)
      .map { |options| Integer(options.to_h["attempt"], exception: false).to_i }

    [ prior_attempts.max.to_i, 0 ].max + 1
  end
end
