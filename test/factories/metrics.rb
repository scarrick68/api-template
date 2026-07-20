FactoryBot.define do
  factory :metric do
    occurred_at { Time.current }
    name { "observability.test.the_thing" }
    metric_type { "counter" }
    value { 1 }
    request_id { "req-#{SecureRandom.hex(6)}" }
    user_id { nil }
    visitor_token { nil }
    labels { {} }
    properties { {} }

    transient do
      http_method { "GET" }
      controller_name { "Api::V1::UsersController" }
      action_name { "show" }
      http_status { 200 }
      request_path { "/api/v1/users/me" }
    end

    trait :api_request do
      name { Metric::API_REQUEST_COUNT }
      metric_type { "counter" }
      value { 1 }
      labels do
        {
          method: http_method,
          controller: controller_name,
          action: action_name,
          status: http_status
        }
      end
      properties do
        {
          path: request_path,
          duration_ms: 12
        }
      end
    end

    trait :api_request_count do
      name { Metric::API_REQUEST_COUNT }
      metric_type { "counter" }
      value { 1 }
      labels do
        {
          method: http_method,
          controller: controller_name,
          action: action_name,
          status: http_status
        }
      end
      properties do
        {
          path: request_path,
          duration_ms: 12
        }
      end
    end

    trait :api_request_duration do
      name { Metric::API_REQUEST_DURATION_MS }
      metric_type { "histogram" }
      value { 12 }
      labels do
        {
          method: http_method,
          controller: controller_name,
          action: action_name,
          status: http_status
        }
      end
      properties { { path: request_path } }
    end

    trait :api_request_app_compute_duration do
      name { Metric::API_REQUEST_APP_COMPUTE_DURATION_MS }
      metric_type { "histogram" }
      value { 12 }
      labels do
        {
          method: http_method,
          controller: controller_name,
          action: action_name,
          status: http_status
        }
      end
      properties { { path: request_path } }
    end

    trait :api_request_db_duration do
      name { Metric::API_REQUEST_DB_DURATION_MS }
      metric_type { "histogram" }
      value { 12 }
      labels do
        {
          method: http_method,
          controller: controller_name,
          action: action_name,
          status: http_status
        }
      end
      properties { { path: request_path } }
    end

    trait :api_request_view_duration do
      name { Metric::API_REQUEST_VIEW_DURATION_MS }
      metric_type { "histogram" }
      value { 12 }
      labels do
        {
          method: http_method,
          controller: controller_name,
          action: action_name,
          status: http_status
        }
      end
      properties { { path: request_path } }
    end
  end
end
