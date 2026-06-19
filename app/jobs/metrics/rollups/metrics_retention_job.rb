module Metrics
  module Rollups
    class MetricsRetentionJob < ApplicationJob
      queue_as :metrics

      RAW_METRICS_RETENTION = 30.days
      HOURLY_ROLLUP_RETENTION = 90.days
      DAILY_ROLLUP_RETENTION = 2.years

      def perform
        Metric.where("occurred_at < ?", RAW_METRICS_RETENTION.ago).delete_all

        Rollup.where(interval: "hour")
              .where("time < ?", HOURLY_ROLLUP_RETENTION.ago)
              .delete_all

        Rollup.where(interval: "day")
              .where("time < ?", DAILY_ROLLUP_RETENTION.ago)
              .delete_all
      end
    end
  end
end
