# frozen_string_literal: true

require "uri"

module LocalProd
  class EnvSetup
    ENV_FILENAME = ".env.production.local"

    DEFAULT_PORT = "5001"
    DEFAULT_WEB_ORIGIN = "http://localhost:3000"
    DEFAULT_POSTGRES_HOST = "localhost"
    DEFAULT_POSTGRES_PORT = "5432"
    DEFAULT_OPENSEARCH_URL = "http://127.0.0.1:9200"
    DEFAULT_SECRET_KEY_BASE = "prod-local-debug-secret-key-base"

    def initialize(
      root_path:,
      env: ENV,
      stderr: $stderr,
      database_catalog_reader: nil
    )
      @root_path = root_path
      @env = env
      @stderr = stderr
      @database_catalog_reader = database_catalog_reader
    end

    def ensure_env_file!
      if File.exist?(env_file_path)
        ensure_existing_env_defaults!
        return false
      end

      File.write(env_file_path, default_env_contents)

      stderr.puts("Created #{ENV_FILENAME} with inferred defaults.")
      stderr.puts("Review and adjust the values as needed for your machine.")

      true
    end

    def env_file_path
      File.join(root_path, ENV_FILENAME)
    end

    def database_diagnostics
      {
        "development_configured" => development_database_name,
        "production_configured" => production_database_name,
        "inferred_from_development" => inferred_development_database_name,
        "selected_database" => selected_database_name,
        "existing_databases" => existing_database_names
      }
    end

    private

    attr_reader :root_path, :env, :stderr, :database_catalog_reader

    def default_env_contents
      port = env.fetch("PORT", DEFAULT_PORT)
      database_url = resolved_database_url

      <<~ENVVARS
        RAILS_ENV=production
        RACK_ENV=production

        PORT=#{port}
        APP_HOST=localhost:#{port}
        APP_PROTOCOL=http

        DATABASE_URL=#{database_url}
        BLAZER_DATABASE_URL=#{database_url}
        OPENSEARCH_URL=#{env.fetch("OPENSEARCH_URL", DEFAULT_OPENSEARCH_URL)}
        CORS_ALLOWED_ORIGINS=#{env.fetch("CORS_ALLOWED_ORIGINS", DEFAULT_WEB_ORIGIN)}

        SECRET_KEY_BASE=#{env.fetch("SECRET_KEY_BASE", DEFAULT_SECRET_KEY_BASE)}
        DTA_SEND_CONFIRMATION_EMAIL=false
      ENVVARS
    end

    def ensure_existing_env_defaults!
      file_contents = File.read(env_file_path)
      missing_defaults = {}

      unless env_key_present?(file_contents, "CORS_ALLOWED_ORIGINS")
        missing_defaults["CORS_ALLOWED_ORIGINS"] = env.fetch("CORS_ALLOWED_ORIGINS", DEFAULT_WEB_ORIGIN)
      end

      return if missing_defaults.empty?

      appended_lines = missing_defaults.map { |key, value| "#{key}=#{value}" }
      separator = file_contents.end_with?("\n") ? "" : "\n"
      File.write(env_file_path, "#{file_contents}#{separator}#{appended_lines.join("\n")}\n")

      stderr.puts("Added missing local defaults to #{ENV_FILENAME}: #{missing_defaults.keys.join(", ")}")
    end

    def env_key_present?(file_contents, key)
      file_contents.match?(/^#{Regexp.escape(key)}=/)
    end

    def resolved_database_url
      explicit_url = env["DATABASE_URL"].to_s.strip
      return explicit_url unless explicit_url.empty?

      ensure_catalog_has_databases!
      ensure_selected_database_exists!

      connection = database_connection_settings
      auth = database_auth(connection[:username], connection[:password])

      "postgres://#{auth}#{connection[:host]}:#{connection[:port]}/#{selected_database_name}"
    end

    def database_connection_settings
      @database_connection_settings ||= {
        host: env.fetch(
          "PGHOST",
          production_config.fetch(
            "host",
            development_config.fetch("host", DEFAULT_POSTGRES_HOST)
          )
        ).to_s,
        port: env.fetch(
          "PGPORT",
          production_config.fetch(
            "port",
            development_config.fetch("port", DEFAULT_POSTGRES_PORT)
          )
        ).to_s,
        username: env.fetch(
          "PGUSER",
          production_config.fetch(
            "username",
            development_config.fetch("username", "")
          )
        ).to_s,
        password: env.fetch(
          "PGPASSWORD",
          production_config.fetch(
            "password",
            development_config.fetch("password", "")
          )
        ).to_s
      }
    end

    def database_auth(username, password)
      return "" if username.empty?

      encoded_username = URI.encode_www_form_component(username)
      auth = encoded_username

      unless password.empty?
        encoded_password = URI.encode_www_form_component(password)
        auth = "#{encoded_username}:#{encoded_password}"
      end

      "#{auth}@"
    end

    def development_config
      @development_config ||= database_config_for("development")
    end

    def production_config
      @production_config ||= database_config_for("production")
    end

    def database_config_for(environment)
      configurations = ActiveRecord::Base.configurations

      config = first_configuration(configurations.configs_for(
        env_name: environment,
        name: "primary"
      ))

      config ||= first_configuration(configurations.configs_for(env_name: environment))

      config ? config.configuration_hash.transform_keys(&:to_s) : {}
    end

    def first_configuration(config_result)
      return config_result.first if config_result.is_a?(Array)

      config_result
    end

    def development_database_name
      development_config.fetch("database", "").to_s.strip
    end

    def production_database_name
      production_config.fetch("database", "").to_s.strip
    end

    def inferred_development_database_name
      return development_database_name unless development_database_name.empty?

      "#{inferred_app_name}_development"
    end

    def selected_database_name
      @selected_database_name ||= inferred_development_database_name
    end

    def existing_database_names
      @existing_database_names ||= begin
        connection = database_connection_settings

        if database_catalog_reader
          database_catalog_reader.call(**connection)
        else
          query_existing_database_names(**connection)
        end
      end
    end

    def query_existing_database_names(host:, port:, username:, password:)
      ActiveRecord::Base.connection.select_values(<<~SQL)
        SELECT datname
        FROM pg_database
        WHERE datistemplate = false
        ORDER BY datname
      SQL
    rescue ActiveRecord::ActiveRecordError => e
      raise StandardError,
            "Could not query PostgreSQL database catalog at #{host}:#{port}. " \
            "Check PGHOST/PGPORT/PGUSER/PGPASSWORD and local database availability. " \
            "Original error: #{e.message}"
    end

    def ensure_catalog_has_databases!
      return unless existing_database_names.empty?

      raise StandardError,
            "PostgreSQL returned no non-template database names. " \
            "Cannot infer local production DATABASE_URL from catalog."
    end

    def ensure_selected_database_exists!
      return if existing_database_names.include?(selected_database_name)

      raise StandardError,
        "Selected development database '#{selected_database_name}' was not found on this PostgreSQL server. " \
            "Create it or set DATABASE_URL in #{ENV_FILENAME}."
    end

    def inferred_app_name
      File.basename(root_path).tr("-", "_")
    end
  end
end
