COVERAGE_ENABLED = ENV.fetch("COVERAGE", "true").casecmp("true").zero?
ENFORCE_BRANCH_COVERAGE = ENV.fetch("ENFORCE_BRANCH_COVERAGE", "false").casecmp("true").zero?

if COVERAGE_ENABLED
  require "simplecov"

  SimpleCov.start "rails" do
    enable_coverage :branch

    cover "{app,lib}/**/*.rb"

    skip "/test/"
    skip "/config/"
    skip "/vendor/"
    skip "/docs/"

    # These are test / dev artifacts that were only used to validate or test at a time when no
    # other artifacts were available. They are not part of the app and should be ignored for coverage.
    skip "/app/jobs/hello_world_job.rb"
    skip "/app/policies/hello_world_policy.rb"
    skip "/app/controllers/test_errors_controller.rb"

    group "Models", "app/models"
    group "Controllers", "app/controllers"
    group "Jobs", "app/jobs"
    group "Services", "app/services"
    group "Commands", "app/services/commands"
    group "Tasks", "lib/tasks"

    minimum_coverage 80
    minimum_coverage branch: 80 if ENFORCE_BRANCH_COVERAGE
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

      # Reindex models for parallel tests
      User.reindex
    end

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Provide create/build shortcuts in tests (e.g., create(:user)).
    include FactoryBot::Syntax::Methods

    # Enable in tests where needed.
    Searchkick.disable_callbacks
  end
end
