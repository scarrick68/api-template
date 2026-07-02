FactoryBot.define do
  factory :data_import_run do
    association :data_artifact
    schema_name { data_artifact.schema_name }
    schema_version { data_artifact.schema_version || "v1" }
    mode { "import" }
    status { "pending" }
    records_seen { 0 }
    records_imported { 0 }
    records_failed { 0 }
    error_details { [] }
    options { {} }
  end
end
