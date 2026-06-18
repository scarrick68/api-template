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

    trait :api_request do
      name { Metric::API_REQUEST_COUNT }
      metric_type { "counter" }
      value { 1 }
      labels do
        {
          method: "GET",
          controller: "Api::V1::UsersController",
          action: "show",
          status: 200
        }
      end
      properties do
        {
          path: "/api/v1/users/me",
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
          method: "GET",
          controller: "Api::V1::UsersController",
          action: "show",
          status: 200
        }
      end
      properties { { path: "/api/v1/users/me" } }
    end
  end
end
