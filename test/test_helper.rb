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

    parallelize_setup do |worker|
      Searchkick.index_suffix = worker

      # reindex models for parallel tests
      User.reindex
    end

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Provide create/build shortcuts in tests (e.g., create(:user)).
    include FactoryBot::Syntax::Methods

    # enable in tests where needed
    Searchkick.disable_callbacks
  end
end
