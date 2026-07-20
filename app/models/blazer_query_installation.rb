class BlazerQueryInstallation < ApplicationRecord
  belongs_to :blazer_query, class_name: "Blazer::Query", optional: true

  validates :query_key, presence: true
  validates :query_version, presence: true
  validates :query_version, uniqueness: { scope: :query_key }
end
