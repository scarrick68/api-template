# frozen_string_literal: true

class DataImportRun < ApplicationRecord
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
end
