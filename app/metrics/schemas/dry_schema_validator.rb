module Schemas
  class DrySchemaValidator
    class ValidationError < StandardError; end

    def self.validate!(schema, payload)
      result = schema.call(payload)
      return result.to_h if result.success?

      errors = result.errors(full: true).map(&:text)
      message = errors.any? ? errors.join(", ") : "Schema validation failed"
      raise ValidationError, message
    end
  end
end
