FactoryBot.define do
  factory :data_artifact do
    sequence(:artifact_id) { |n| "artifact-#{n}" }
    schema_name { "test_schema_name" }
    schema_version { "v1" }
    source { "test" }
    status { "pending" }
  end
end
