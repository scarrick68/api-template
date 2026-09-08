module Api
  module V1
    # Receives client-side web/mobile error reports and forwards them into Rails.error.
    class ErrorsController < BaseController
      class ClientReportedError < StandardError
      end

      SUPPORTED_CLIENTS = %w[mobile web].freeze

      def create
        attributes = error_report_params

        error = ClientReportedError.new(attributes.dig(:error, :message) || "Client error reported")
        error.set_backtrace(normalized_backtrace(attributes.dig(:error, :stack)))

        Rails.error.report(
          error,
          handled: true,
          source: "client",
          context: report_context(attributes)
        )

        render_serialized(Api::V1::BaseBlueprint, { success: true }, status: :accepted)
      end

      private

      def error_report_params
        params.permit(
          :client,
          :origin,
          :handled,
          error: [ :name, :message, :stack ],
          context: {}
        ).to_h.deep_symbolize_keys
      end

      def report_context(attributes)
        {
          client: normalized_client(attributes[:client]),
          origin: normalized_origin(attributes[:origin]),
          reported_handled: attributes[:handled].nil? ? true : attributes[:handled],
          error_name: attributes.dig(:error, :name),
          user_id: current_user&.id,
          request_id: request.request_id,
          explicit_context: attributes[:context] || {}
        }.compact
      end

      def normalized_backtrace(stack)
        return [] if stack.blank?

        stack.to_s.split("\n").first(100)
      end

      def normalized_client(client)
        value = client.to_s.strip.downcase
        return value if SUPPORTED_CLIENTS.include?(value)

        "unknown"
      end

      def normalized_origin(origin)
        value = origin.to_s.strip
        return value if value.present?

        "application"
      end
    end
  end
end
