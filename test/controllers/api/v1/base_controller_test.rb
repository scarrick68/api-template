require "test_helper"

module Api
  module V1
    class BaseControllerTest < ActiveSupport::TestCase
      test "rescue handlers include API input contract and authorization failures" do
        handlers = BaseController.rescue_handlers.to_h

        assert_equal :render_contract_invalid, handlers["ApplicationContract::Invalid"]
        assert_equal :render_not_authorized, handlers["ApplicationPolicy::NotAuthorized"]
      end

      test "authorize! raises when policy denies action" do
        controller = build_controller(action_name: "show")

        error = assert_raises(ApplicationPolicy::NotAuthorized) do
          controller.send(:authorize!, Object.new)
        end

        assert_match("Not authorized to show?", error.message)
      end

      private

      def build_controller(action_name:)
        controller = BaseController.new
        controller.define_singleton_method(:action_name) { action_name }
        controller.define_singleton_method(:current_user) { nil }
        controller
      end
    end
  end
end
