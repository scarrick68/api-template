# frozen_string_literal: true

module Schemas
  module DataImports
    # Contract for manifest payload shape accepted by the data import pipeline.
    ManifestSchema = Dry::Schema.Params do
      config.validate_keys = true

      required(:artifact_id).filled(:string)
      required(:schema_name).filled(:string)
      required(:schema_version).filled(:string)
      required(:record_count).filled(:integer)
      required(:created_at).filled(:time)

      optional(:files).array(:hash) do
        required(:name).filled(:string)
        optional(:checksum).maybe(:string)
        optional(:byte_size).maybe(:integer)
      end
    end
  end
end
