FactoryBot.define do
  factory :metric do
    occurred_at { Time.current }
    name { "observability.test.the_thing" }
    request_id { "req-#{SecureRandom.hex(6)}" }
    user_id { nil }
    visitor_token { nil }

    trait :api_request do
      name { "observability.api.request" }
      properties do
        {
          method: "GET",
          path: "/api/v1/users/me",
          controller: "Api::V1::UsersController",
          action: "show",
          status: 200,
          duration_ms: 12
        }
      end
    end
  end
end
