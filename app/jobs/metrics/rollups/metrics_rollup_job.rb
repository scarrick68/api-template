module Metrics
  module Rollups
    class MetricsRollupJob < ApplicationJob
      queue_as :metrics

      def perform(period: "hour", window_start: nil, window_end: nil)
        Metrics::Rollups::ApiObservabilityJob.perform_now(
          period: period,
          window_start: window_start,
          window_end: window_end
        )

        Metrics::Rollups::ApiEndpointsJob.perform_now(
          period: period,
          window_start: window_start,
          window_end: window_end
        )

        Searchjoy::SearchjoyRollupsJob.perform_now(
          period: period,
          window_start: window_start,
          window_end: window_end
        )
      end
    end
  end
end
