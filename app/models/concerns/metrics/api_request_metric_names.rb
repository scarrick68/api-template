module Metrics
  module ApiRequestMetricNames
    API_REQUEST_COUNT = "observability.api.request.count".freeze
    API_REQUEST_DURATION_MS = "observability.api.request.duration_ms".freeze

    VALID_METRIC_NAMES = [
      API_REQUEST_COUNT,
      API_REQUEST_DURATION_MS
    ].freeze
  end
end
