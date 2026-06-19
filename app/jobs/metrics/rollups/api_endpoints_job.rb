# app/jobs/metrics/rollups/api_endpoints_job.rb
module Metrics
  module Rollups
    class ApiEndpointsJob < ApplicationJob
      include Metrics::RollupHelpers

      queue_as :metrics

      ROLLUPS = {
        endpoint_requests: "observability.api.endpoint.requests",
        endpoint_client_errors: "observability.api.endpoint.client_errors",
        endpoint_server_errors: "observability.api.endpoint.server_errors",
        endpoint_duration_avg_ms: "observability.api.endpoint.duration.avg_ms",
        endpoint_duration_p95_ms: "observability.api.endpoint.duration.p95_ms"
      }.freeze

      def perform(period: "hour", window_start: nil, window_end: nil)
        @window = build_window(
          period: period,
          window_start: window_start,
          window_end: window_end
        )

        upsert_endpoint_requests
        upsert_endpoint_client_errors
        upsert_endpoint_server_errors
        upsert_endpoint_duration_avg
        upsert_endpoint_duration_p95
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

      def upsert_endpoint_duration_avg
        Metric.where(occurred_at: @window.start_time...@window.end_time)
          .where(name: Metric::API_REQUEST_DURATION_MS)
          .group(controller_sql, action_sql)
          .average(:value)
          .each do |(controller, action), value|
            upsert_endpoint_rollup(
              name: ROLLUPS[:endpoint_duration_avg_ms],
              window: @window,
              controller: controller,
              action: action,
              value: value
            )
          end
      end

      def upsert_endpoint_client_errors
        Metric.where(occurred_at: @window.start_time...@window.end_time)
          .where(name: Metric::API_REQUEST_COUNT)
          .where(Arel.sql("(#{status_sql}) between 400 and 499"))
          .group(controller_sql, action_sql)
          .sum(:value)
          .each do |(controller, action), value|
            upsert_endpoint_rollup(
              name: ROLLUPS[:endpoint_client_errors],
              window: @window,
              controller: controller,
              action: action,
              value: value
            )
          end
      end

      def upsert_endpoint_server_errors
        Metric.where(occurred_at: @window.start_time...@window.end_time)
          .where(name: Metric::API_REQUEST_COUNT)
          .where(Arel.sql("(#{status_sql}) between 500 and 599"))
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
