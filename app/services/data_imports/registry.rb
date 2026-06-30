# frozen_string_literal: true

module DataImports
  module Registry
    IMPORTERS = {
      [ "restaurants", "v1" ] => "DataImports::Restaurants::V1Importer"
    }.freeze

    def self.fetch(schema_name, schema_version)
      key = [ schema_name.to_s, schema_version.to_s ]
      importer = IMPORTERS.fetch(key) do
        raise KeyError, "No importer registered for schema_name=#{schema_name.inspect} schema_version=#{schema_version.inspect}"
      end

      importer.is_a?(String) ? importer.constantize : importer
    end
  end
end
