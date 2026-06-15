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
