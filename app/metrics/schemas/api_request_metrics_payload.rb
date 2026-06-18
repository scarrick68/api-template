module Schemas
  ApiRequestMetricsPayload = Dry::Schema.Params do
    config.validate_keys = true

    required(:occurred_at).filled(:time)
    required(:request_id).maybe(:string)
    required(:user_id).maybe(:integer)
    required(:visitor_token).maybe(:string)
    required(:method).filled(:string, included_in?: %w[GET POST PUT PATCH DELETE])
    required(:path).filled(:string)
    required(:controller).filled(:string, format?: /\AApi::/)
    required(:action).filled(:string)
    required(:status).filled(:integer, gteq?: 100, lteq?: 599)
    required(:duration_ms).filled(:integer, gteq?: 0)
  end
end
