
module Subscribers
  module Observability
    class ApiRequestSubscriber
      def self.call(*args)
        event = ActiveSupport::Notifications::Event.new(*args)
        payload = event.payload
        duration_ms = event.duration.round
        db_duration_ms = payload[:db_runtime]&.round.to_i
        view_duration_ms = payload[:view_runtime]&.round.to_i
        app_compute_duration_ms = [ duration_ms - db_duration_ms - view_duration_ms, 0 ].max

        return unless payload[:controller]&.start_with?("Api::")

        ApiRequestMetricsJob.perform_later(
          occurred_at: Time.at(event.time).iso8601,
          request_id: payload[:request]&.request_id,
          user_id: payload[:user_id],
          visitor_token: payload[:visitor_token],
          method: payload[:method],
          path: payload[:path],
          controller: payload[:controller],
          action: payload[:action],
          status: payload[:status],
          duration_ms: duration_ms,
          db_duration_ms: db_duration_ms,
          view_duration_ms: view_duration_ms,
          app_compute_duration_ms: app_compute_duration_ms
        )
      end
    end
  end
end
