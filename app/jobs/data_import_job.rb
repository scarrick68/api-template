# frozen_string_literal: true

# Dispatches import runs to schema/version-specific importer implementations.
class DataImportJob < ApplicationJob
  queue_as :data_imports

  def perform(import_run_id)
    run = DataImportRun.find(import_run_id)
    run.update!(status: :running, started_at: Time.current)

    importer = DataImports::Registry.fetch(run.schema_name, run.schema_version)
    importer.call(run: run)

    run.update!(status: :succeeded, finished_at: Time.current)
  rescue StandardError => e
    if run
      run.update!(
        status: :failed,
        finished_at: Time.current,
        error_details: Array(run.error_details) + [
          {
            "class" => e.class.name,
            "message" => e.message
          }
        ]
      )
    end

    raise
  end
end
