module Api
  module V1
    class BaseController < Api::BaseController
      include Pagy::Method

      rescue_from ApplicationContract::Invalid, with: :render_contract_invalid
      rescue_from ApplicationPolicy::NotAuthorized, with: :render_not_authorized

      private

      def render_serialized(blueprint, payload, status: :ok)
        render(
          json: blueprint.render_as_hash(payload.merge(api_request_context)),
          status: status
        )
      end

      def paginate_scope(scope, page:, per_page:)
        pagy(scope, page: page, limit: per_page)
      end

      def pagination_meta(pagy, extras = {})
        pagy.data_hash.merge(extras)
      end

      def authorize!(record, query = nil)
        action = query || "#{action_name}?"
        allowed = policy_for(record).public_send(action)

        raise ApplicationPolicy::NotAuthorized, "Not authorized to #{action}" unless allowed

        true
      end

      def policy_for(record)
        class_name = record.is_a?(Class) ? record.name : record.class.name
        policy_class = "#{class_name}Policy".safe_constantize || ApplicationPolicy
        policy_class.new(current_user, record)
      end

      def render_contract_invalid(exception)
        render_api_error(
          type: "unprocessable_entity",
          message: "Validation failed",
          details: exception.errors,
          status: :unprocessable_entity
        )
      end

      def render_not_authorized(_exception)
        render_api_error(
          type: "forbidden",
          message: "You are not authorized to perform this action",
          status: :forbidden
        )
      end
    end
  end
end
