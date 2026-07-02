# frozen_string_literal: true

module Commands
  module DataImports
    # Starts a DataImportRun for an existing DataArtifact and enqueues DataImportJob.
    class StartRunCommand
      MODES = %w[dry_run import].freeze

      def self.call(...)
        new(...).call
      end

      def initialize(data_artifact_id:, mode: "import")
        @data_artifact_id = data_artifact_id
        @mode = mode.to_s.presence || "import"
      end

      def call
        validate_inputs!
        ::DataImports::StartRun.call(data_artifact:, mode:)
      end

      private

      attr_reader :data_artifact_id, :mode

      def data_artifact
        @data_artifact ||= DataArtifact.find(data_artifact_id)
      end

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
end
