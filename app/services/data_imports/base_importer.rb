# frozen_string_literal: true

module DataImports
  # Base contract for schema/version-specific importers.
  class BaseImporter
    def self.call(...)
      new(...).call
    end

    def initialize(run:)
      @run = run
    end

    def call
      raise NotImplementedError, "#{self.class.name} must implement #call"
    end

    private

    attr_reader :run
  end
end
