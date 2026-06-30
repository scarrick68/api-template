# frozen_string_literal: true

class DataArtifact < ApplicationRecord
  has_one_attached :file
  has_many :data_import_runs, dependent: :destroy

  enum :status,
       {
         pending: "pending",
         validated: "validated",
         invalid: "invalid",
         imported: "imported"
       },
       default: :pending,
       prefix: :status,
       validate: true

  validates :artifact_id, :schema_name, presence: true
end
