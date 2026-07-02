# frozen_string_literal: true

module DataImports
  class StartRun
    include AttemptNumbering

    MODES = %w[dry_run import].freeze

    def self.call(...)
      new(...).call
    end

    def initialize(data_artifact:, mode:)
      @data_artifact = data_artifact
      @mode = mode.to_s
    end

    def call
      validate_inputs!

      data_import_run = DataImportRun.create!(
        data_artifact: data_artifact,
        schema_name: data_artifact.schema_name,
        schema_version: data_artifact.schema_version,
        mode: mode,
        status: :pending,
        options: { "attempt" => next_attempt_number_for(data_artifact: data_artifact, mode: mode) }
      )

      DataImportJob.perform_later(data_import_run.id)
      data_import_run
    end

    private

    attr_reader :data_artifact, :mode

    def validate_inputs!
      unless MODES.include?(mode)
        raise ArgumentError, "Unsupported mode=#{mode.inspect}. Expected one of: #{MODES.join(', ')}"
      end

      unless data_artifact.ready_for_import?
        raise ArgumentError, "DataArtifact ##{data_artifact.id} is not ready_for_import? (requires a valid record and schema_version)"
      end
    end
  end
end
