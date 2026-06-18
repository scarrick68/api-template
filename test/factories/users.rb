FactoryBot.define do
  factory :user do
    name { "Test User" }
    sequence(:email) { |n| "user#{n}@example.com" }
    provider { "email" }
    uid { email }
    password { "password123" }
    password_confirmation { "password123" }
    admin { false }
    allow_password_change { false }
    confirmation_sent_at { 5.minutes.ago }
    confirmed_at { Time.current }

    trait :admin do
      admin { true }
    end

    trait :unconfirmed do
      confirmed_at { nil }
      confirmation_sent_at { Time.current }
      sequence(:confirmation_token) { |n| "confirmation-token-#{n}" }
    end

    trait :soft_deleted do
      deleted_at { Time.current }
    end

    trait :reindex do
      after(:create) do |user, _|
        user.reindex(refresh: true)
      end
    end

    trait :with_field_test_membership do
      transient do
        experiment_name { "user_signup_flow" }
        experiment_variant { "control" }
        converted { false }
      end

      after(:create) do |user, evaluator|
        FieldTest::Membership.create!(
          experiment: evaluator.experiment_name,
          variant: evaluator.experiment_variant,
          converted: evaluator.converted,
          participant_type: "User",
          participant_id: user.id.to_s
        )
      end
    end
  end
end
