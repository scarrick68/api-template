require "test_helper"

module Api
  module V1
    class UsersMeObservabilityTest < ApplicationDispatchTest
      include ActiveJob::TestHelper

      test "/me captures observability api request event (any api route should work)" do
        user = create(:user, email: "observability-me@example.com")

        perform_enqueued_jobs do
          assert_difference "Metric.where(name: Metric::API_REQUEST_COUNT).count", 1 do
            assert_difference "Metric.where(name: Metric::API_REQUEST_DURATION_MS).count", 1 do
              assert_difference "Metric.where(name: Metric::API_REQUEST_DB_DURATION_MS).count", 1 do
                assert_difference "Metric.where(name: Metric::API_REQUEST_VIEW_DURATION_MS).count", 1 do
                  assert_difference "Metric.where(name: Metric::API_REQUEST_APP_COMPUTE_DURATION_MS).count", 1 do
                    get "/api/v1/users/me", headers: auth_headers_for(user)
                  end
                end
              end
            end
          end
        end

        assert_response :success

        metric = Metric.where(name: Metric::API_REQUEST_COUNT).last
        response_request_id = response.parsed_body["request_id"]

        assert_not_nil metric
        assert_equal response_request_id, metric.request_id

        labels = metric.labels.with_indifferent_access
        assert_equal "GET", labels[:method]
        assert_equal "Api::V1::UsersController", labels[:controller]
        assert_equal "me", labels[:action]
        assert_equal 200, labels[:status]

        duration_metric = Metric.where(name: Metric::API_REQUEST_DURATION_MS).last
        assert_equal "/api/v1/users/me", duration_metric.properties["path"]

        db_duration_metric = Metric.where(name: Metric::API_REQUEST_DB_DURATION_MS).last
        view_duration_metric = Metric.where(name: Metric::API_REQUEST_VIEW_DURATION_MS).last
        app_duration_metric = Metric.where(name: Metric::API_REQUEST_APP_COMPUTE_DURATION_MS).last
        assert_equal "/api/v1/users/me", db_duration_metric.properties["path"]
        assert_equal "/api/v1/users/me", view_duration_metric.properties["path"]
        assert_equal "/api/v1/users/me", app_duration_metric.properties["path"]
      end
    end
  end
end
