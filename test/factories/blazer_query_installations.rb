FactoryBot.define do
  factory :blazer_query_installation do
    sequence(:query_key) { |n| "query_key_#{n}" }
    query_version { 1 }
    association :blazer_query
    installed_at { Time.current }
  end
end
