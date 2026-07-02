# frozen_string_literal: true

module DataImports
  # Base contract for schema/version-specific importers.
  #
  # Subclasses implement #perform_import and can rely on:
  # - dry_run? to branch behavior
  # - persist_enabled? to guard writes
  # - default dry-run execution strategy that runs importer logic in a
  #   transaction and rolls it back.
  class BaseImporter
    def self.call(...)
      new(...).call
    end

    def initialize(data_import_run:)
      @data_import_run = data_import_run
    end

    def call
      return run_dry_run if dry_run?

      perform_import
    end

    private

    attr_reader :data_import_run

    def perform_import
      raise NotImplementedError, "#{self.class.name} must implement #perform_import"
    end

    def dry_run?
      data_import_run.mode.to_s == "dry_run"
    end

    def import_mode?
      data_import_run.mode.to_s == "import"
    end

    def persist_enabled?
      !dry_run?
    end

    # Default dry-run behavior runs full importer logic in a rollback-only
    # transaction so writes are blocked while parsing/validation logic still runs.
    def run_dry_run
      case dry_run_strategy
      when :transaction_rollback
        ActiveRecord::Base.transaction(requires_new: true) do
          perform_import
          raise ActiveRecord::Rollback
        end
      when :validate_only
        perform_validation_only
      else
        raise ArgumentError, "Unsupported dry_run strategy: #{dry_run_strategy.inspect}"
      end
    end

    # Subclasses may override when rollback strategy is not suitable.
    def dry_run_strategy
      :transaction_rollback
    end

    # Subclasses can implement this and switch dry_run_strategy to :validate_only.
    def perform_validation_only
      perform_import
    end
  end
end
