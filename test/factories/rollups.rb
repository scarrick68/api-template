FactoryBot.define do
  factory :rollup do
    name { "observability.api.endpoint.requests" }
    interval { "day" }
    time { Time.current.beginning_of_day }
    dimensions { { "controller" => "Api::V1::UsersController", "action" => "index" } }
    value { 1.0 }
  end
end
