module Api
  module V1
    class BaseController < Api::BaseController
      rescue_from ApplicationContract::Invalid, with: :render_contract_invalid

      private

      def render_contract_invalid(exception)
        render_api_error(
          type: "unprocessable_entity",
          message: "Validation failed",
          details: exception.errors,
          status: :unprocessable_entity
        )
      end
    end
  end
end
