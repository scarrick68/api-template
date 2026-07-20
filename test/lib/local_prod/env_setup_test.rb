require "test_helper"
require "fileutils"
require "tmpdir"
require "stringio"
require_relative "../../../lib/local_prod/env_setup"

class LocalProdEnvSetupTest < ActiveSupport::TestCase
  test "queries live database catalog through active record connection" do
    current_database = ActiveRecord::Base.connection_db_config.database.to_s
    setup = LocalProd::EnvSetup.new(root_path: Rails.root.to_s)

    diagnostics = setup.database_diagnostics
    databases = diagnostics.fetch("existing_databases")

    assert_includes databases, current_database
  end

  test "creates .env.production.local with inferred database url from development config" do
    Dir.mktmpdir("local-prod-env-setup") do |tmpdir|
      stderr = StringIO.new
      setup = LocalProd::EnvSetup.new(
        root_path: tmpdir,
        stderr: stderr,
        database_catalog_reader: ->(**_kwargs) { [ "renamed_app_development" ] }
      )
      setup.stubs(:database_config_for).with("development").returns(
        {
          "database" => "renamed_app_development",
          "host" => "127.0.0.1",
          "port" => 5433,
          "username" => "dev_user",
          "password" => "dev_pass"
        }
      )
      setup.stubs(:database_config_for).with("production").returns({})

      created = setup.ensure_env_file!
      env_path = File.join(tmpdir, ".env.production.local")
      user_env_path = File.join(tmpdir, ".env.production.local.user")
      env_contents = File.read(env_path)

      assert created
      assert File.exist?(env_path)
      assert File.exist?(user_env_path)
      assert_includes env_contents, "DATABASE_URL=postgres://dev_user:dev_pass@127.0.0.1:5433/renamed_app_development"
      assert_includes env_contents, "BLAZER_DATABASE_URL=postgres://dev_user:dev_pass@127.0.0.1:5433/renamed_app_development"
      assert_includes env_contents, "CORS_ALLOWED_ORIGINS=http://localhost:3000"
      assert_includes env_contents, "PORT=5001"
      assert_includes env_contents, "APP_HOST=localhost:5001"
      assert_includes stderr.string, "Created .env.production.local with inferred defaults."
      assert_includes stderr.string, "Created .env.production.local.user for local overrides"
    end
  end

  test "does not overwrite existing .env.production.local" do
    Dir.mktmpdir("local-prod-env-preserve") do |tmpdir|
      env_path = File.join(tmpdir, ".env.production.local")
      File.write(env_path, "DATABASE_URL=postgres://localhost:5432/custom\nCORS_ALLOWED_ORIGINS=http://localhost:3000\n")

      setup = LocalProd::EnvSetup.new(root_path: tmpdir)
      created = setup.ensure_env_file!

      refute created
      assert_equal "DATABASE_URL=postgres://localhost:5432/custom\nCORS_ALLOWED_ORIGINS=http://localhost:3000\n", File.read(env_path)
    end
  end

  test "creates user override file when missing without affecting generated file" do
    Dir.mktmpdir("local-prod-user-env-create") do |tmpdir|
      generated_env_path = File.join(tmpdir, ".env.production.local")
      user_env_path = File.join(tmpdir, ".env.production.local.user")
      File.write(generated_env_path, "DATABASE_URL=postgres://localhost:5432/custom\nCORS_ALLOWED_ORIGINS=http://localhost:3000\n")

      setup = LocalProd::EnvSetup.new(root_path: tmpdir)
      created = setup.ensure_env_file!

      refute created
      assert File.exist?(user_env_path)
      assert_equal "DATABASE_URL=postgres://localhost:5432/custom\nCORS_ALLOWED_ORIGINS=http://localhost:3000\n", File.read(generated_env_path)
    end
  end

  test "does not overwrite existing user override file" do
    Dir.mktmpdir("local-prod-user-env-preserve") do |tmpdir|
      generated_env_path = File.join(tmpdir, ".env.production.local")
      user_env_path = File.join(tmpdir, ".env.production.local.user")
      File.write(generated_env_path, "DATABASE_URL=postgres://localhost:5432/custom\nCORS_ALLOWED_ORIGINS=http://localhost:3000\n")
      File.write(user_env_path, "DATABASE_URL=postgres://localhost:5432/override\n")

      setup = LocalProd::EnvSetup.new(root_path: tmpdir)
      setup.ensure_env_file!

      assert_equal "DATABASE_URL=postgres://localhost:5432/override\n", File.read(user_env_path)
    end
  end

  test "backfills cors origins for existing env file" do
    Dir.mktmpdir("local-prod-env-backfill") do |tmpdir|
      env_path = File.join(tmpdir, ".env.production.local")
      File.write(env_path, "DATABASE_URL=postgres://localhost:5432/custom\n")

      stderr = StringIO.new
      setup = LocalProd::EnvSetup.new(root_path: tmpdir, stderr: stderr)
      created = setup.ensure_env_file!

      refute created
      file_contents = File.read(env_path)
      assert_includes file_contents, "DATABASE_URL=postgres://localhost:5432/custom"
      assert_includes file_contents, "CORS_ALLOWED_ORIGINS=http://localhost:3000"
      assert_includes stderr.string, "Added missing local defaults to .env.production.local: CORS_ALLOWED_ORIGINS"
    end
  end

  test "raises when catalog returns no database names" do
    Dir.mktmpdir("my-app-template") do |tmpdir|
      setup = LocalProd::EnvSetup.new(
        root_path: tmpdir,
        database_catalog_reader: ->(**_kwargs) { [] }
      )
      setup.stubs(:database_config_for).with("development").returns({})
      setup.stubs(:database_config_for).with("production").returns({})

      error = assert_raises(StandardError) do
        setup.ensure_env_file!
      end

      assert_includes error.message, "PostgreSQL returned no non-template database names"
    end
  end

  test "uses discovered development database from db catalog when config name is absent" do
    Dir.mktmpdir("catalog-derived-development-db") do |tmpdir|
      setup = LocalProd::EnvSetup.new(
        root_path: tmpdir,
        database_catalog_reader: ->(**_kwargs) { [ "catalog_derived_development", "catalog_derived_production" ] }
      )
      setup.stubs(:database_config_for).with("development").returns(
        {
          "host" => "localhost",
          "port" => 5432
        }
      )
      setup.stubs(:database_config_for).with("production").returns({})
      setup.stubs(:inferred_app_name).returns("catalog_derived")

      setup.ensure_env_file!
      env_contents = File.read(File.join(tmpdir, ".env.production.local"))

      assert_includes env_contents, "DATABASE_URL=postgres://localhost:5432/catalog_derived_development"
    end
  end

  test "raises when selected development database does not exist in catalog" do
    Dir.mktmpdir("catalog-missing-production-db") do |tmpdir|
      setup = LocalProd::EnvSetup.new(
        root_path: tmpdir,
        database_catalog_reader: ->(**_kwargs) { [ "postgres" ] }
      )
      setup.stubs(:database_config_for).with("development").returns({ "database" => "product_api_development" })
      setup.stubs(:database_config_for).with("production").returns({})

      error = assert_raises(StandardError) do
        setup.ensure_env_file!
      end

      assert_includes error.message, "Selected development database 'product_api_development' was not found"
      assert_includes error.message, "Create it or set DATABASE_URL in .env.production.local.user"
    end
  end

  test "uses development database even when production database exists" do
    setup = LocalProd::EnvSetup.new(
      root_path: Rails.root.to_s,
      database_catalog_reader: ->(**_kwargs) { [ "api_template_development", "api_template_production", "postgres" ] }
    )
    setup.stubs(:database_config_for).with("development").returns({ "database" => "api_template_development" })
    setup.stubs(:database_config_for).with("production").returns({ "database" => "api_template_production" })

    diagnostics = setup.database_diagnostics

    assert_equal "api_template_development", diagnostics.fetch("selected_database")
  end
end
