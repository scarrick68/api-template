FactoryBot.define do
  factory :blazer_query, class: "Blazer::Query" do
    sequence(:name) { |n| "Blazer Query #{n}" }
    data_source { "main" }
    statement { "SELECT 1" }
  end
end
