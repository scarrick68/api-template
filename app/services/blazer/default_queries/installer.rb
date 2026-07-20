module Blazer
  module DefaultQueries
    class Installer
      Error = Class.new(StandardError)

      Result = Data.define(:installed, :skipped)

      REQUIRED_STRING_FIELDS = %i[key name dashboard_group data_source sql_statement].freeze

      def call
        validate!

        installed = []
        skipped = []

        query_definitions.each do |definition|
          if install_or_skip(definition) == :skipped
            skipped << definition
            next
          end

          installed << definition
        end

        Result.new(installed: installed.freeze, skipped: skipped.freeze)
      end

      private

      def validate!
        unless query_definitions.is_a?(Array)
          raise Error, "Default query definitions must be an array."
        end

        query_definitions.each do |definition|
          validate_definition!(definition)
        end

        validate_unique_key_versions!
      end

      def validate_definition!(definition)
        query_identifier = definition_identifier(definition)

        unless definition.is_a?(Definition)
          raise Error, "Default query '#{query_identifier}' must be a #{Definition.name} object."
        end

        REQUIRED_STRING_FIELDS.each do |field|
          value = definition.public_send(field)
          next if value.is_a?(String) && value.strip != ""

          raise Error, "Default query '#{query_identifier}' has an invalid #{field}."
        end

        if definition.version.is_a?(Integer) && definition.version.positive?
          return
        end

        raise Error, "Default query '#{query_identifier}' must have a positive integer version."
      end

      def definition_identifier(definition)
        name = if definition.respond_to?(:name)
          definition.name
        elsif definition.is_a?(Hash)
          definition[:name] || definition["name"]
        end

        version = if definition.respond_to?(:version)
          definition.version
        elsif definition.is_a?(Hash)
          definition[:version] || definition["version"]
        end

        normalized_name = name.to_s.strip
        normalized_name = "unknown" if normalized_name == ""

        normalized_version = version.nil? ? "unknown" : version
        "#{normalized_name} v#{normalized_version}"
      end

      def validate_unique_key_versions!
        duplicate_key_versions = query_definitions
          .group_by { |definition| [ definition.key, definition.version ] }
          .select { |_key_version, matches| matches.size > 1 }
          .keys
        return if duplicate_key_versions.empty?

        details = duplicate_key_versions.map { |key, version| "#{key}@v#{version}" }.sort.join(", ")
        raise Error, "Duplicate default query key+version pairs: #{details}."
      end

      def installed?(definition)
        BlazerQueryInstallation.exists?(
          query_key: definition.key,
          query_version: definition.version
        )
      end

      def install(definition)
        ApplicationRecord.transaction do
          query = Blazer::Query.create!(
            name: query_name_for(definition),
            data_source: definition.data_source,
            statement: definition.sql_statement
          )

          BlazerQueryInstallation.create!(
            query_key: definition.key,
            query_version: definition.version,
            blazer_query: query,
            installed_at: Time.current
          )
        end

        :installed
      end

      def query_name_for(definition)
        "#{definition.name} v#{definition.version}"
      end

      def install_or_skip(definition)
        return :skipped if installed?(definition)

        install(definition)
      end

      def query_definitions
        @query_definitions ||= Definitions.all
      end
    end
  end
end
