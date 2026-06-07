module Api
  module V1
    class BaseController < Api::BaseController
      rescue_from ApplicationContract::Invalid, with: :render_contract_invalid
      rescue_from ApplicationPolicy::NotAuthorized, with: :render_not_authorized

      private

      def render_serialized(blueprint, payload, status: :ok)
        render(
          json: blueprint.render_as_hash(payload.merge(api_request_context)),
          status: status
        )
      end

      def authorize!(record, query = nil)
        action = query || "#{action_name}?"
        allowed = policy_for(record).public_send(action)

        raise ApplicationPolicy::NotAuthorized, "Not authorized to #{action}" unless allowed

        true
      end

      def policy_for(record)
        policy_class = "#{record.class.name}Policy".safe_constantize || ApplicationPolicy
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
