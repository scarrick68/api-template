module SearchkickBulkReindexConcurrency
  extend ActiveSupport::Concern

  included do
    include GoodJob::ActiveJobExtensions::Concurrency

    good_job_control_concurrency_with(
      total_limit: 3,
      key: -> { "searchkick_bulk_reindex" }
    )
  end
end

Rails.application.config.after_initialize do
  Searchkick::BulkReindexJob.include(SearchkickBulkReindexConcurrency)
end
