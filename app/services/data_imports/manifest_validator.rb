# frozen_string_literal: true

module DataImports
  # Validates manifest payloads and persists validation state onto the artifact.
  class ManifestValidator
    Result = Struct.new(:success?, :manifest, :errors, keyword_init: true)

    def self.call(payload:, artifact: nil)
      validation_result = Schemas::DataImports::ManifestSchema.call(payload)
      validation_errors = extract_validation_errors(validation_result)

      if validation_result.success? && validation_errors.empty?
        return build_valid_result(validation_result, artifact)
      end

      build_invalid_result(validation_errors, artifact)
    end

    def self.build_valid_result(validation_result, artifact)
      normalized_manifest = validation_result.to_h
      persist_valid_artifact_state(artifact, normalized_manifest) if artifact

      Result.new(success?: true, manifest: normalized_manifest, errors: [])
    end

    def self.build_invalid_result(validation_errors, artifact)
      persist_invalid_artifact_state(artifact, validation_errors) if artifact

      Result.new(success?: false, manifest: nil, errors: validation_errors)
    end

    def self.extract_validation_errors(validation_result)
      validation_result.errors(full: true).map(&:text)
    end

    def self.persist_valid_artifact_state(artifact, manifest)
      artifact.apply_manifest_valid!(manifest: manifest)
    end

    def self.persist_invalid_artifact_state(artifact, errors)
      artifact.apply_manifest_invalid!(errors: errors)
    end

    private_class_method :build_valid_result,
                         :build_invalid_result,
                         :extract_validation_errors,
                         :persist_valid_artifact_state,
                         :persist_invalid_artifact_state
  end
end
