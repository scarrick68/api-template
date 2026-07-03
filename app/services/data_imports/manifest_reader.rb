# frozen_string_literal: true

module DataImports
  # Loads an attached manifest file, parses JSON, and runs schema validation.
  class ManifestReader
    def self.call(artifact:)
      new(artifact:).call
    end

    def initialize(artifact:)
      @artifact = artifact
    end

    def call
      unless artifact.file.attached?
        return failure_with_artifact_update([ "Manifest file is not attached" ])
      end

      payload = JSON.parse(artifact.file.download)
      DataImports::ManifestValidator.call(payload:, artifact:)
    rescue JSON::ParserError
      failure_with_artifact_update([ "Manifest file is not valid JSON" ])
    end

    private

    attr_reader :artifact

    def failure_with_artifact_update(errors)
      artifact.apply_manifest_invalid!(errors: errors)

      DataImports::ManifestValidator::Result.new(success?: false, manifest: nil, errors: errors)
    end
  end
end
