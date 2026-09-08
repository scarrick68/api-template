FactoryBot.define do
  factory :push_device do
    association :user
    sequence(:push_token) { |n| "ExponentPushToken[token-#{n}]" }
    platform { "ios" }
    app_version { "1.0.0" }
    build_version { "1" }
    active { true }
    last_registered_at { Time.current }
  end
end
