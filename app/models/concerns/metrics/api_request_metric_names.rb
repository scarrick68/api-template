module Metrics
  module ApiRequestMetricNames
    API_REQUEST_COUNT = "observability.api.request.count".freeze
    API_REQUEST_DURATION_MS = "observability.api.request.duration_ms".freeze
    API_REQUEST_DB_DURATION_MS = "observability.api.request.duration.db_ms".freeze
    API_REQUEST_VIEW_DURATION_MS = "observability.api.request.duration.view_ms".freeze
    API_REQUEST_APP_COMPUTE_DURATION_MS = "observability.api.request.duration.app_compute_ms".freeze

    VALID_METRIC_NAMES = [
      API_REQUEST_COUNT,
      API_REQUEST_DURATION_MS,
      API_REQUEST_DB_DURATION_MS,
      API_REQUEST_VIEW_DURATION_MS,
      API_REQUEST_APP_COMPUTE_DURATION_MS
    ].freeze
  end
end
