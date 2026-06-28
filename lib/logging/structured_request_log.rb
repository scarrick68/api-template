module Logging
  # Builds the canonical structured request log payload consumed by Lograge.
  module StructuredRequestLog
    HTTP_EVENT_NAME = "http_request".freeze

    def self.ignore_event?(event)
      payload = event.payload
      payload[:method].blank? || payload[:path].blank?
    end

    def self.lograge_custom_options(event)
      payload = event.payload
      request = payload[:request]

      {
        timestamp: Time.at(event.time).utc.iso8601(3),
        severity: "INFO",
        event: HTTP_EVENT_NAME,
        request_id: payload[:request_id] || request&.request_id,
        admin_id: payload[:admin_id],
        user_id: payload[:user_id],
        visitor_token: payload[:visitor_token],
        method: payload[:method],
        path: payload[:path],
        controller: payload[:controller],
        action: payload[:action],
        status: payload[:status],
        request_duration: event.duration&.round(2),
        db_duration: payload[:db_runtime]&.round(2),
        remote_ip: payload[:remote_ip] || request&.remote_ip
      }
    end
  end
end
