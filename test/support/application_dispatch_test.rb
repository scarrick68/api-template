require_relative "api_auth_helpers"

class ApplicationDispatchTest < ActionDispatch::IntegrationTest
  include ApiAuthHelpers
end
