# -----------------------------------------------------------------------------
# Coverage
# -----------------------------------------------------------------------------
# IMPORTANT: SimpleCov must start before Rails/application code is required.
# Otherwise files loaded during application boot will not be tracked correctly.

COVERAGE_ENABLED = ENV.fetch("COVERAGE", "true").casecmp("true").zero?
ENFORCE_BRANCH_COVERAGE = ENV.fetch("ENFORCE_BRANCH_COVERAGE", "false").casecmp("true").zero?

if COVERAGE_ENABLED
  require "simplecov"

  SimpleCov.start "rails" do
    enable_coverage :branch

    # Limit coverage to application and library code.
    cover "{app,lib}/**/*.rb"

    # Exclude non-application code from coverage calculations.
    skip "/test/"
    skip "/config/"
    skip "/vendor/"
    skip "/docs/"

    # Test/dev-only artifacts that are not part of normal application behavior.
    skip "/app/jobs/hello_world_job.rb"
    skip "/app/policies/hello_world_policy.rb"
    skip "/app/controllers/test_errors_controller.rb"

    # Organize the generated coverage report by application layer.
    group "Models", "app/models"
    group "Controllers", "app/controllers"
    group "Jobs", "app/jobs"
    group "Services", "app/services"
    group "Commands", "app/services/commands"
    group "Tasks", "lib/tasks"

    # Line coverage is always enforced when coverage is enabled.
    # Branch coverage is collected by default but only enforced explicitly.
    minimum_coverage 80
    minimum_coverage branch: 80 if ENFORCE_BRANCH_COVERAGE
  end
end

# -----------------------------------------------------------------------------
# Rails test environment
# -----------------------------------------------------------------------------
# Set the environment before loading the Rails application.

ENV["RAILS_ENV"] ||= "test"

# Loading the application must happen after SimpleCov starts.
require_relative "../config/environment"

# -----------------------------------------------------------------------------
# Test framework and test-only dependencies
# -----------------------------------------------------------------------------

require "rails/test_help"
require "mocha/minitest"
require "skooma"

# -----------------------------------------------------------------------------
# OpenAPI contract testing
# -----------------------------------------------------------------------------
# Enable Skooma's coverage reporting only when the main coverage run is enabled.

path_to_openapi = Rails.root.join("docs", "openapi.yml")

if COVERAGE_ENABLED
  ActionDispatch::IntegrationTest.include Skooma::Minitest[path_to_openapi, coverage: :report]
else
  ActionDispatch::IntegrationTest.include Skooma::Minitest[path_to_openapi]
end

# -----------------------------------------------------------------------------
# Shared test support
# -----------------------------------------------------------------------------
# Load support files after Rails and test dependencies are available.
# Sorting keeps load order deterministic.

Dir[Rails.root.join("test/support/**/*.rb")].sort.each do |file|
  require file
end

# -----------------------------------------------------------------------------
# Global ActiveSupport test configuration
# -----------------------------------------------------------------------------

module ActiveSupport
  class TestCase
    # Run tests in parallel using available processors.
    parallelize(workers: :number_of_processors)

    # Configure per-worker external state after each parallel worker starts.
    parallelize_setup do |worker|
      # Keep Searchkick indexes isolated between workers.
      Searchkick.index_suffix = worker

      # Populate each worker's isolated search index before tests run.
      User.reindex
    end

    # Load all fixtures for ActiveSupport-based tests.
    fixtures :all

    # Provide FactoryBot create/build shortcuts.
    include FactoryBot::Syntax::Methods

    # Search indexing is opt-in per test to avoid unnecessary indexing work.
    Searchkick.disable_callbacks
  end
end
