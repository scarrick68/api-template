# frozen_string_literal: true

class DataImportRun < ApplicationRecord
  include AASM

  belongs_to :data_artifact

  enum :status,
       {
         pending: "pending",
         running: "running",
         succeeded: "succeeded",
         failed: "failed",
         cancelled: "cancelled"
       },
       default: :pending,
       prefix: :status,
       validate: true

  validates :schema_name, :schema_version, presence: true

  aasm column: :status, enum: true, namespace: :pipeline do
    state :pending, initial: true
    state :running
    state :succeeded
    state :failed
    state :cancelled

    event :start_processing, before: :set_started_at_if_missing do
      transitions from: %i[pending running], to: :running
    end

    event :mark_succeeded, before: :set_finished_at_if_missing do
      transitions from: :running, to: :succeeded
    end

    event :mark_failed, before: %i[set_finished_at_if_missing append_error_detail] do
      transitions from: %i[pending running failed], to: :failed
    end

    event :cancel, before: :set_finished_at_if_missing do
      transitions from: %i[pending running], to: :cancelled
    end
  end

  private

  def set_started_at_if_missing(*)
    self.started_at ||= Time.current
  end

  def set_finished_at_if_missing(*)
    self.finished_at ||= Time.current
  end

  def append_error_detail(error = nil)
    return if error.nil?

    self.error_details = Array(error_details) + [
      {
        "class" => error.class.name,
        "message" => error.message
      }
    ]
  end
end
