# frozen_string_literal: true

# Dispatches import runs to schema/version-specific importer implementations.
class DataImportJob < ApplicationJob
  queue_as :data_imports
  RETRY_ATTEMPTS = 3

  retry_on StandardError, attempts: RETRY_ATTEMPTS, wait: 0.seconds do |job, error|
    data_import_run_id = job.arguments.first
    DataImportJob.mark_failed!(data_import_run_id, error)
  end

  def perform(data_import_run_id)
    data_import_run = DataImportRun.find(data_import_run_id)
    data_import_run.update!(status: :running, started_at: data_import_run.started_at || Time.current)

    importer = DataImports::Registry.fetch(data_import_run.schema_name, data_import_run.schema_version)
    importer.call(data_import_run: data_import_run)

    data_import_run.update!(status: :succeeded, finished_at: Time.current)
  end

  def self.mark_failed!(data_import_run_id, error)
    data_import_run = DataImportRun.find_by(id: data_import_run_id)
    return unless data_import_run

    data_import_run.update!(
      status: :failed,
      finished_at: Time.current,
      error_details: Array(data_import_run.error_details) + [
        {
          "class" => error.class.name,
          "message" => error.message
        }
      ]
    )
  end
end
