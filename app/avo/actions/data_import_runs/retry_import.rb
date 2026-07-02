class Avo::Actions::DataImportRuns::RetryImport < Avo::BaseAction
  self.name = "Data Import Runs/Retry Import"
  self.message = "Create retry runs for selected import runs and enqueue DataImportJob."

  def handle(query:, **)
    enqueued = 0

    query.each do |previous_run|
      artifact = previous_run.data_artifact
      next unless artifact
      next if previous_run.schema_name.blank? || previous_run.schema_version.blank?

      run = DataImportRun.create!(
        data_artifact: artifact,
        schema_name: previous_run.schema_name,
        schema_version: previous_run.schema_version,
        mode: previous_run.mode.presence || "import",
        status: :pending,
        options: previous_run.options.presence || {}
      )

      DataImportJob.perform_later(run.id)
      enqueued += 1
    end

    if enqueued.zero?
      fail "No retry runs were created from the selected records."
    else
      succeed "Created and enqueued #{enqueued} retry run(s)."
    end
  rescue StandardError => e
    fail "Retry import failed: #{e.message}"
  end
end
