# frozen_string_literal: true

module DataImports
  module AttemptNumbering
    private

    def next_attempt_number_for(data_artifact:, mode:)
      prior_attempts = DataImportRun
        .where(
          data_artifact_id: data_artifact.id,
          schema_name: data_artifact.schema_name,
          schema_version: data_artifact.schema_version,
          mode: mode
        )
        .pluck(:options)
        .map { |options| Integer(options.to_h["attempt"], exception: false).to_i }

      [ prior_attempts.max.to_i, 0 ].max + 1
    end
  end
end
