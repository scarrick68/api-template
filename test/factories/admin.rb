FactoryBot.define do
  factory :admin do
    sequence(:email) { |n| "admin#{n}@example.com" }

    password { "password123" }
    password_confirmation { password }

    sign_in_count { 0 }
    failed_attempts { 0 }

    trait :locked do
      locked_at { Time.current }
      failed_attempts { Devise.maximum_attempts }
    end

    trait :with_user do
      association :user
    end
  end
end
