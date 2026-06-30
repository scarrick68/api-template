# frozen_string_literal: true

module Commands
  module DataArtifacts
    # Creates a DataArtifact from a local file path for local/dev operator workflows.
    class UploadLocalCommand
      def self.call(...)
        new(...).call
      end

      def initialize(file_path:, schema_name:, schema_version: nil, source: "rake_upload_local")
        @file_path = file_path.to_s
        @schema_name = schema_name.to_s
        @schema_version = schema_version
        @source = source.presence || "rake_upload_local"
      end

      def call
        validate_inputs!

        artifact = DataArtifact.create!(
          artifact_id: build_artifact_id,
          schema_name: schema_name,
          schema_version: schema_version,
          source: source,
          status: :pending
        )

        attach_file!(artifact)
        update_file_metadata!(artifact)
        maybe_validate_manifest!(artifact)

        artifact
      end

      private

      attr_reader :file_path, :schema_name, :schema_version, :source

      def validate_inputs!
        if file_path.blank? || schema_name.blank?
          raise ArgumentError, "Usage: bin/rails \"data_artifacts:upload_local[tmp/file.ndjson,customer_accounts,v1,manual]\""
        end

        raise ArgumentError, "FILE not found: #{expanded_path}" unless File.exist?(expanded_path)
      end

      def expanded_path
        @expanded_path ||= begin
          path = Pathname.new(file_path)
          path.absolute? ? path : Rails.root.join(path)
        end
      end

      def build_artifact_id
        base = File.basename(expanded_path, ".*").parameterize(separator: "_")
        timestamp = Time.current.utc.strftime("%Y%m%d%H%M%S")

        "#{base}-#{timestamp}"
      end

      def attach_file!(artifact)
        File.open(expanded_path, "rb") do |io|
          artifact.file.attach(
            io: io,
            filename: File.basename(expanded_path),
            content_type: Marcel::MimeType.for(expanded_path, name: File.basename(expanded_path))
          )
        end

        artifact.reload
      end

      def update_file_metadata!(artifact)
        metadata = (artifact.metadata || {}).dup
        metadata["uploaded_via"] = "rake"

        artifact.update!(
          byte_size: artifact.file.blob.byte_size,
          checksum: artifact.file.blob.checksum,
          content_type: artifact.file.blob.content_type,
          metadata: metadata,
          status: :pending
        )
      end

      def maybe_validate_manifest!(artifact)
        return unless artifact.file.filename.extension.to_s.downcase == "json"

        DataImports::ManifestReader.call(artifact:)
      end
    end
  end
end
