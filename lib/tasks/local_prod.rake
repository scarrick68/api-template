# frozen_string_literal: true

require_relative "../local_prod/env_setup"

namespace :local_prod do
  desc "Create .env.production.local with inferred defaults (no overwrite if it already exists)"
  task setup_env: :environment do
    LocalProd::EnvSetup.new(root_path: Rails.root.to_s).ensure_env_file!
  rescue StandardError => e
    abort(e.message)
  end

  # bundle exec rails local_prod:list_databases
  desc "List development/production database names and existing PostgreSQL databases"
  task list_databases: :environment do
    diagnostics = LocalProd::EnvSetup.new(root_path: Rails.root.to_s).database_diagnostics

    puts "development configured: #{diagnostics.fetch('development_configured')}"
    puts "production configured:  #{diagnostics.fetch('production_configured')}"
    puts "inferred candidate:     #{diagnostics.fetch('inferred_from_development')}"
    puts "selected for env file:  #{diagnostics.fetch('selected_database')}"

    existing_databases = diagnostics.fetch("existing_databases")
    puts "existing databases:"
    existing_databases.each do |database_name|
      puts "- #{database_name}"
    end
  rescue StandardError => e
    abort(e.message)
  end
end
