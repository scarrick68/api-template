class ApiRequestMetricsBuilder
  def self.call(payload)
    data = payload.with_indifferent_access
    occurred_at_value = data.fetch(:occurred_at)
    occurred_at = occurred_at_value.is_a?(Time) ? occurred_at_value : Time.iso8601(occurred_at_value)
    status = data.fetch(:status).to_i
    now = Time.current

    common = {
      occurred_at: occurred_at,
      request_id: data[:request_id],
      user_id: data[:user_id],
      visitor_token: data[:visitor_token],
      labels: {
        method: data[:method],
        controller: data[:controller],
        action: data[:action],
        status: status
      },
      properties: {
        path: data[:path]
      },
      created_at: now,
      updated_at: now
    }

    rows = [
      common.merge(
        name: Metric::API_REQUEST_COUNT,
        metric_type: "counter",
        value: 1
      ),
      common.merge(
        name: Metric::API_REQUEST_DURATION_MS,
        metric_type: "histogram",
        value: data[:duration_ms]
      ),
      common.merge(
        name: Metric::API_REQUEST_DB_DURATION_MS,
        metric_type: "histogram",
        value: data[:db_duration_ms]
      ),
      common.merge(
        name: Metric::API_REQUEST_VIEW_DURATION_MS,
        metric_type: "histogram",
        value: data[:view_duration_ms]
      ),
      common.merge(
        name: Metric::API_REQUEST_APP_COMPUTE_DURATION_MS,
        metric_type: "histogram",
        value: data[:app_compute_duration_ms]
      )
    ]

    rows
  end
end
