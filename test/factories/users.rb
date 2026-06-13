FactoryBot.define do
  factory :user do
    name { "Test User" }
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password123" }
    password_confirmation { "password123" }
    confirmed_at { Time.current }

    trait :admin do
      admin { true }
    end

    trait :reindex do
      after(:create) do |user, _|
        user.reindex(refresh: true)
      end
    end
  end
end
