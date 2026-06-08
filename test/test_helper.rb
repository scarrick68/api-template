ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "mocha/minitest"
require "skooma"

path_to_openapi = Rails.root.join("docs", "openapi.yml")
ActionDispatch::IntegrationTest.include Skooma::Minitest[path_to_openapi, coverage: :report]

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Provide create/build shortcuts in tests (e.g., create(:user)).
    include FactoryBot::Syntax::Methods

    # Add more helper methods to be used by all tests here...
  end
end
