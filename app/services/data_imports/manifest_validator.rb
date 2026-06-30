# frozen_string_literal: true

module DataImports
  # Validates manifest payloads and persists validation state onto the artifact.
  class ManifestValidator
    Result = Struct.new(:success?, :manifest, :errors, keyword_init: true)

    def self.call(payload:, artifact: nil)
      result = Schemas::DataImports::ManifestSchema.call(payload)

      if result.success?
        normalized = result.to_h
        mark_artifact_validated(artifact, normalized) if artifact

        return Result.new(success?: true, manifest: normalized, errors: [])
      end

      errors = result.errors(full: true).map(&:text)
      mark_artifact_invalid(artifact, errors) if artifact

      Result.new(success?: false, manifest: nil, errors: errors)
    end

    def self.mark_artifact_validated(artifact, manifest)
      metadata = (artifact.metadata || {}).dup
      metadata["manifest"] = manifest
      metadata["manifest_validation_errors"] = []

      artifact.update!(status: :validated, metadata: metadata)
    end

    def self.mark_artifact_invalid(artifact, errors)
      metadata = (artifact.metadata || {}).dup
      metadata["manifest_validation_errors"] = errors

      artifact.update!(status: :invalid, metadata: metadata)
    end

    private_class_method :mark_artifact_validated, :mark_artifact_invalid
  end
end
