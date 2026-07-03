# frozen_string_literal: true

# Dispatches import runs to schema/version-specific importer implementations.
class DataImportJob < ApplicationJob
  queue_as :data_imports
  RETRY_ATTEMPTS = 3

  retry_on StandardError, attempts: RETRY_ATTEMPTS, wait: 5.seconds do |job, error|
    data_import_run_id = job.arguments.first
    DataImportJob.mark_failed!(data_import_run_id, error)
  end

  def perform(data_import_run_id)
    data_import_run = DataImportRun.find(data_import_run_id)
    data_import_run.start_processing!

    importer = DataImports::Registry.fetch(data_import_run.schema_name, data_import_run.schema_version)
    importer.call(data_import_run: data_import_run)

    data_import_run.mark_succeeded!
  end

  def self.mark_failed!(data_import_run_id, error)
    data_import_run = DataImportRun.find_by(id: data_import_run_id)
    return unless data_import_run

    data_import_run.mark_failed!(error)
  end
end
