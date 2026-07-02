class Avo::Actions::DataImportRuns::RetryImport < Avo::BaseAction
  self.name = "Data Import Runs/Retry Import"
  self.message = "Create retry runs for selected import runs and enqueue DataImportJob."

  def handle(query:, **)
    enqueued = 0
    blocked_in_progress = 0

    query.each do |previous_run|
      artifact = previous_run.data_artifact
      next unless artifact
      next if previous_run.schema_name.blank? || previous_run.schema_version.blank?
      unless retryable_failed_run?(previous_run)
        blocked_in_progress += 1 if previous_run.status_running? || previous_run.status_pending?
        next
      end

      if retry_in_progress?(previous_run)
        blocked_in_progress += 1
        next
      end

      run = DataImportRun.create!(
        data_artifact: artifact,
        schema_name: previous_run.schema_name,
        schema_version: previous_run.schema_version,
        mode: previous_run.mode.presence || "import",
        status: :pending,
        options: retry_options(previous_run)
      )

      DataImportJob.perform_later(run.id)
      enqueued += 1
    end

    if enqueued.zero?
      if blocked_in_progress.positive?
        fail "Retry cannot be created because a run is currently in progress. Wait for the run to finish and try again."
      else
        fail "No retry runs were created from the selected records."
      end
    else
      succeed "Created and enqueued #{enqueued} retry run(s)."
    end
  rescue StandardError => e
    fail "Retry import failed: #{e.message}"
  end

  private

  def retryable_failed_run?(previous_run)
    previous_run.status_failed? && previous_run.finished_at.present?
  end

  def retry_in_progress?(previous_run)
    candidate_scope = DataImportRun.where(
      data_artifact_id: previous_run.data_artifact_id,
      schema_name: previous_run.schema_name,
      schema_version: previous_run.schema_version,
      mode: previous_run.mode.presence || "import",
      status: %w[pending running]
    )

    candidate_scope.any? do |candidate|
      candidate.options.to_h["retry_of_data_import_run_id"].to_s == previous_run.id.to_s
    end
  end

  def retry_options(previous_run)
    previous_run.options.to_h.merge(
      "attempt" => next_attempt_number(previous_run),
      "retry_of_data_import_run_id" => previous_run.id
    )
  end

  def next_attempt_number(previous_run)
    current = Integer(previous_run.options.to_h["attempt"], exception: false)
    base = current.to_i
    base = 1 if base < 1

    base + 1
  end
end
