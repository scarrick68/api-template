COVERAGE_ENABLED = ENV.fetch("COVERAGE", "false").casecmp("true").zero?

if COVERAGE_ENABLED
  require "simplecov"
  require "fileutils"

  FileUtils.mkdir_p(File.expand_path("../tmp", __dir__)) unless File.exist?(File.expand_path("../tmp", __dir__))

  SimpleCov.enable_coverage :branch
  SimpleCov.coverage_dir "coverage"
  SimpleCov.merge_timeout 3600

  SimpleCov.start "rails" do
    add_filter "/test/"
    add_filter "/config/"
    add_filter "/vendor/"
    add_filter "/docs/"

    add_group "Models", "app/models"
    add_group "Controllers", "app/controllers"
    add_group "Jobs", "app/jobs"
    add_group "Services", "app/services"
    minimum_coverage line: 80, branch: 80
  end
end

ENV["RAILS_ENV"] ||= "test"

require_relative "../config/environment"
require "rails/test_help"
require "mocha/minitest"
require "skooma"

path_to_openapi = Rails.root.join("docs", "openapi.yml")
if COVERAGE_ENABLED
  ActionDispatch::IntegrationTest.include Skooma::Minitest[path_to_openapi, coverage: :report]
else
  ActionDispatch::IntegrationTest.include Skooma::Minitest[path_to_openapi]
end

Dir[Rails.root.join("test/support/**/*.rb")].sort.each do |file|
  require file
end

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    parallelize_setup do |worker|
      Searchkick.index_suffix = worker
      SimpleCov.command_name "#{SimpleCov.command_name}-#{worker}" if COVERAGE_ENABLED

      # reindex models for parallel tests
      User.reindex
    end

    parallelize_teardown do |worker|
      SimpleCov.result if COVERAGE_ENABLED
    end

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Provide create/build shortcuts in tests (e.g., create(:user)).
    include FactoryBot::Syntax::Methods

    # enable in tests where needed
    Searchkick.disable_callbacks
  end
end
