require "test_helper"

module Api
  module V1
    class BaseControllerTest < ActiveSupport::TestCase
      test "rescue handlers include API input contract and authorization failures" do
        handlers = Api::V1::BaseController.rescue_handlers.to_h

        assert_equal :render_contract_invalid, handlers["ApplicationContract::Invalid"]
        assert_equal :render_not_authorized, handlers["ApplicationPolicy::NotAuthorized"]
      end

      test "authorize! raises when policy denies action" do
        controller = build_controller

        error = with_controller_context(controller, action_name: "show") do
          assert_raises(ApplicationPolicy::NotAuthorized) do
            controller.send(:authorize!, Object.new)
          end
        end

        assert_match("Not authorized to show?", error.message)
      end

      test "includes pagy method support" do
        controller = build_controller

        assert_equal true, controller.respond_to?(:pagy, true)
      end

      test "paginate_scope paginates a scope with page and per_page" do
        create_list(:user, 3)
        controller = build_controller

        pagy, records = with_controller_context(controller, action_name: "index") do
          controller.send(
            :paginate_scope,
            User.order(:id),
            page: 1,
            per_page: 2
          )
        end

        assert_equal 1, pagy.page
        assert_equal 2, pagy.limit
        assert_equal 2, records.size
      end

      test "pagination_meta merges pagy data hash with extras" do
        create_list(:user, 2)
        controller = build_controller
        pagy, _records = with_controller_context(controller, action_name: "index") do
          controller.send(:paginate_scope, User.order(:id), page: 1, per_page: 1)
        end

        meta = controller.send(:pagination_meta, pagy, { filter: "active" })

        assert_equal 1, meta[:page]
        assert_equal 1, meta[:limit]
        assert_equal "active", meta[:filter]
      end

      test "policy_for resolves policy from record class" do
        current_user = build(:user, :admin)
        controller = build_controller

        policy = with_controller_context(controller, action_name: "index", current_user: current_user) do
          controller.send(:policy_for, User)
        end

        assert_instance_of UserPolicy, policy
        assert_equal current_user, policy.user
        assert_equal User, policy.record
      end

      test "policy_for resolves policy from record instance" do
        current_user = build(:user, :admin)
        record = build(:user)
        controller = build_controller

        policy = with_controller_context(controller, action_name: "index", current_user: current_user) do
          controller.send(:policy_for, record)
        end

        assert_instance_of UserPolicy, policy
        assert_equal current_user, policy.user
        assert_equal record, policy.record
      end

      test "policy_for falls back to application policy when specific policy is missing" do
        record = Object.new
        controller = build_controller

        policy = with_controller_context(controller, action_name: "index") do
          controller.send(:policy_for, record)
        end

        assert_instance_of ApplicationPolicy, policy
        assert_equal record, policy.record
      end

      test "rescue handlers are mapped to rendering methods" do
        handlers = Api::V1::BaseController.rescue_handlers.to_h

        assert_equal :render_not_found, handlers["ActiveRecord::RecordNotFound"]
        assert_equal :render_bad_request, handlers["ActionController::ParameterMissing"]
        assert_equal :render_bad_request, handlers["ActionController::BadRequest"]
        assert_equal :render_record_invalid, handlers["ActiveRecord::RecordInvalid"]
        assert_equal :render_record_not_saved, handlers["ActiveRecord::RecordNotSaved"]
        assert_equal :render_internal_server_error, handlers["StandardError"]
      end

      test "render_not_found forwards expected payload" do
        controller, capture = build_controller_capture
        exception = ActiveRecord::RecordNotFound.new("record missing")

        controller.send(:render_not_found, exception)

        assert_equal(
          {
            type: "not_found",
            message: "record missing",
            status: :not_found,
            details: nil
          },
          capture
        )
      end

      test "render_bad_request forwards expected payload" do
        controller, capture = build_controller_capture
        exception = ActionController::BadRequest.new("invalid request")

        controller.send(:render_bad_request, exception)

        assert_equal(
          {
            type: "bad_request",
            message: "invalid request",
            status: :bad_request,
            details: nil
          },
          capture
        )
      end

      test "render_record_invalid forwards validation details" do
        controller, capture = build_controller_capture
        user = User.new
        user.valid?
        exception = ActiveRecord::RecordInvalid.new(user)

        controller.send(:render_record_invalid, exception)

        assert_equal "unprocessable_entity", capture[:type]
        assert_equal user.errors.full_messages.to_sentence, capture[:message]
        assert_equal :unprocessable_entity, capture[:status]
        assert_equal user.errors.full_messages, capture[:details]
      end

      test "render_record_not_saved forwards message and optional details" do
        controller, capture = build_controller_capture
        user = User.new
        user.valid?
        exception = ActiveRecord::RecordNotSaved.new("save failed", user)

        controller.send(:render_record_not_saved, exception)

        assert_equal "unprocessable_entity", capture[:type]
        assert_equal "save failed", capture[:message]
        assert_equal :unprocessable_entity, capture[:status]
        assert_equal user.errors.full_messages, capture[:details]
      end

      test "render_internal_server_error always uses generic message" do
        controller, capture = build_controller_capture

        controller.send(:render_internal_server_error, StandardError.new("boom"))

        assert_equal(
          {
            type: "internal_server_error",
            message: "An unexpected error occurred",
            status: :internal_server_error,
            details: nil
          },
          capture
        )
      end

      private

      def build_controller_capture
        controller = Api::V1::BaseController.new
        capture = {}

        controller.define_singleton_method(:render_api_error) do |type:, message:, status:, details: nil|
          capture[:type] = type
          capture[:message] = message
          capture[:status] = status
          capture[:details] = details
        end

        [ controller, capture ]
      end

      def build_controller
        Api::V1::BaseController.new
      end

      def with_controller_context(controller, action_name:, current_user: nil)
        test_request = ActionDispatch::TestRequest.create

        controller.stubs(:action_name).returns(action_name)
        controller.stubs(:current_user).returns(current_user)
        controller.stubs(:request).returns(test_request)

        yield
      end
    end
  end
end
