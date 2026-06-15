require "test_helper"
require "support/application_dispatch_test"

module Api
  module V1
    class UsersMeObservabilityTest < ApplicationDispatchTest
      setup do
        Metric.delete_all
      end

      test "/me captures observability api request event (any api route should work)" do
        user = create(:user, email: "observability-me@example.com")

        assert_difference "Metric.where(name: 'observability.api.request').count", 1 do
          get "/api/v1/users/me", headers: auth_headers_for(user)
        end

        assert_response :success

        metric = Metric.where(name: "observability.api.request").last
        response_request_id = response.parsed_body["request_id"]

        assert_not_nil metric
        assert_equal response_request_id, metric.request_id

        properties = metric.properties.with_indifferent_access
        assert_equal "GET", properties[:method]
        assert_equal "/api/v1/users/me", properties[:path]
        assert_equal "Api::V1::UsersController", properties[:controller]
        assert_equal "me", properties[:action]
        assert_equal 200, properties[:status]
      end
    end
  end
end
