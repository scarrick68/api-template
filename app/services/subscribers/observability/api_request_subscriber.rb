
module Subscribers
  module Observability
    class ApiRequestSubscriber
      def self.call(*args)
        event = ActiveSupport::Notifications::Event.new(*args)
        payload = event.payload
        event_time = Time.at(event.time)

        return unless payload[:controller]&.start_with?("Api::")

        Metric.create!(
          occurred_at: event_time,
          name: "observability.api.request",
          request_id: payload[:request]&.request_id,
          user_id: payload[:user_id],
          properties: {
            method: payload[:method],
            path: payload[:path],
            controller: payload[:controller],
            action: payload[:action],
            status: payload[:status],
            duration_ms: event.duration.round
          }
        )
      end
    end
  end
end
