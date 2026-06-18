module Metrics
  module ApiRequestMetricNames
    API_REQUEST_COUNT = "observability.api.request.count".freeze
    API_REQUEST_DURATION_MS = "observability.api.request.duration_ms".freeze
    API_REQUEST_ERROR_COUNT = "observability.api.request.error.count".freeze
    API_REQUEST_CLIENT_ERROR_COUNT = "observability.api.request.client_error.count".freeze

    VALID_METRIC_NAMES = [
      API_REQUEST_COUNT,
      API_REQUEST_DURATION_MS,
      API_REQUEST_ERROR_COUNT,
      API_REQUEST_CLIENT_ERROR_COUNT
    ].freeze
  end
end
