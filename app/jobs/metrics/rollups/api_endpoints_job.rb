# app/jobs/metrics/rollups/api_endpoints_job.rb
module Metrics
  module Rollups
    class ApiEndpointsJob < ApplicationJob
      include Metrics::RollupHelpers

      queue_as :metrics

      ROLLUPS = {
        endpoint_requests: "observability.api.endpoint.requests",
        endpoint_duration_p95_ms: "observability.api.endpoint.duration.p95_ms",
        endpoint_server_errors: "observability.api.endpoint.server_errors"
      }.freeze

      def perform(period: "hour", window_start: nil, window_end: nil)
        @window = build_window(
          period: period,
          window_start: window_start,
          window_end: window_end
        )

        upsert_endpoint_requests
        upsert_endpoint_duration_p95
        upsert_endpoint_server_errors
      end

      private

      def upsert_endpoint_requests
        Metric.where(occurred_at: @window.start_time...@window.end_time)
          .where(name: Metric::API_REQUEST_COUNT)
          .group(controller_sql, action_sql)
          .sum(:value)
          .each do |(controller, action), value|
            upsert_endpoint_rollup(
              name: ROLLUPS[:endpoint_requests],
              window: @window,
              controller: controller,
              action: action,
              value: value
            )
          end
      end

      def upsert_endpoint_duration_p95
        Metric.where(occurred_at: @window.start_time...@window.end_time)
          .where(name: Metric::API_REQUEST_DURATION_MS)
          .group(controller_sql, action_sql)
          .pluck(
            controller_sql,
            action_sql,
            Arel.sql("percentile_cont(0.95) within group (order by value)")
          )
          .each do |controller, action, value|
            upsert_endpoint_rollup(
              name: ROLLUPS[:endpoint_duration_p95_ms],
              window: @window,
              controller: controller,
              action: action,
              value: value
            )
          end
      end

      def upsert_endpoint_server_errors
        Metric.where(occurred_at: @window.start_time...@window.end_time)
          .where(name: Metric::API_REQUEST_ERROR_COUNT)
          .group(controller_sql, action_sql)
          .sum(:value)
          .each do |(controller, action), value|
            upsert_endpoint_rollup(
              name: ROLLUPS[:endpoint_server_errors],
              window: @window,
              controller: controller,
              action: action,
              value: value
            )
          end
      end

      def upsert_endpoint_rollup(name:, window:, controller:, action:, value:)
        return if controller.blank? || action.blank?

        upsert_rollup(
          name: name,
          window: window,
          value: value,
          dimensions: {
            controller: controller,
            action: action
          }
        )
      end
    end
  end
end
