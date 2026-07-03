# frozen_string_literal: true

class DataArtifact < ApplicationRecord
  include AASM

  has_one_attached :file
  has_many :data_import_runs, dependent: :destroy

  enum :status,
       {
         pending: "pending",
         valid: "valid",
         invalid: "invalid",
         imported: "imported"
       },
       default: :pending,
       prefix: :status,
       validate: true

  validates :artifact_id, :schema_name, presence: true

  aasm column: :status, enum: true, namespace: :pipeline do
    state :pending, initial: true
    state :valid
    state :invalid
    state :imported

    # Manifest processing can be re-run, so allow idempotent transitions.
    event :validate_manifest do
      transitions from: %i[pending valid invalid], to: :valid
    end

    event :invalidate_manifest do
      transitions from: %i[pending valid invalid], to: :invalid
    end

    event :mark_imported do
      transitions from: :valid, to: :imported
    end
  end

  def apply_manifest_valid!(manifest:)
    with_lock do
      next_metadata = (metadata || {}).dup
      next_metadata["manifest"] = manifest
      next_metadata["manifest_validation_errors"] = []

      self.metadata = next_metadata
      validate_manifest!
    end
  end

  def apply_manifest_invalid!(errors:)
    with_lock do
      next_metadata = (metadata || {}).dup
      next_metadata["manifest_validation_errors"] = errors

      self.metadata = next_metadata
      invalidate_manifest!
    end
  end

  def ready_for_import?
    valid? && schema_version.present?
  end
end
