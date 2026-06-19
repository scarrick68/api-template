module Metrics
  module Rollups
    class ApiObservabilityJob < ApplicationJob
      include Metrics::RollupHelpers

      queue_as :metrics

      ROLLUPS = {
        requests_total: "observability.api.requests.total",
        requests_client_errors: "observability.api.requests.client_errors",
        requests_server_errors: "observability.api.requests.server_errors",
        duration_avg_ms: "observability.api.duration.avg_ms",
        duration_p95_ms: "observability.api.duration.p95_ms"
      }.freeze

      def perform(period: "hour", window_start: nil, window_end: nil)
        window = build_window(
          period: period,
          window_start: window_start,
          window_end: window_end
        )

        scope = Metric.where(occurred_at: window.start_time...window.end_time)
        duration_scope = scope.where(name: Metric::API_REQUEST_DURATION_MS)

        upsert_rollup(
          name: ROLLUPS[:requests_total],
          window: window,
          value: scope.where(name: Metric::API_REQUEST_COUNT).sum(:value)
        )

        upsert_rollup(
          name: ROLLUPS[:requests_client_errors],
          window: window,
          value: scope.where(name: Metric::API_REQUEST_CLIENT_ERROR_COUNT).sum(:value)
        )

        upsert_rollup(
          name: ROLLUPS[:requests_server_errors],
          window: window,
          value: scope.where(name: Metric::API_REQUEST_ERROR_COUNT).sum(:value)
        )

        upsert_rollup(
          name: ROLLUPS[:duration_avg_ms],
          window: window,
          value: duration_scope.average(:value)
        )

        upsert_rollup(
          name: ROLLUPS[:duration_p95_ms],
          window: window,
          value: p95(duration_scope)
        )
      end
    end
  end
end
