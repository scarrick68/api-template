module Schemas
  ApiRequestMetricRow = Dry::Schema.Params do
    config.validate_keys = true

    required(:occurred_at).filled(:time)
    required(:name).filled(:string, included_in?: Metrics::ApiRequestMetricNames::VALID_METRIC_NAMES)
    required(:metric_type).filled(:string, included_in?: Metric::METRIC_TYPES)
    required(:value).filled(:float)
    required(:request_id).filled(:string)
    required(:user_id).maybe(:integer)
    required(:visitor_token).maybe(:string)

    required(:labels).hash do
      required(:method).filled(:string)
      required(:controller).filled(:string)
      required(:action).filled(:string)
      required(:status).filled(:integer, gteq?: 100, lteq?: 599)
    end

    required(:properties).hash do
      required(:path).filled(:string)
    end
  end
end
