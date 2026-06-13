module SearchkickBulkReindexConcurrency
  extend ActiveSupport::Concern

  included do
    limits_concurrency to: 3, key: ""
  end
end

Rails.application.config.after_initialize do
  Searchkick::BulkReindexJob.include(SearchkickBulkReindexConcurrency)
end
