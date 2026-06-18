require "test_helper"
require "ostruct"

module Api
  class BaseControllerTest < ActiveSupport::TestCase
    include ActiveJob::TestHelper
    test "rescue handlers are mapped to rendering methods" do
      handlers = Api::BaseController.rescue_handlers.to_h

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

    test "api request metrics include user_id and visitor_token" do
      user = create(:user)

      controller, payload = build_controller_capture

      controller.stubs(:current_user).returns(user)
      controller.stubs(:ahoy).returns(OpenStruct.new(visitor_token: "visitor-123"))

      controller.send(:append_info_to_payload, payload)

      assert_equal user.id, payload[:user_id]
      assert_equal "visitor-123", payload[:visitor_token]
    end

    test "append_info_to_payload sets nil values when current_user and ahoy are nil" do
      controller, payload = build_controller_capture

      controller.stubs(:current_user).returns(nil)
      controller.stubs(:ahoy).returns(nil)

      controller.send(:append_info_to_payload, payload)

      assert_nil payload[:user_id]
      assert_nil payload[:visitor_token]
    end

    private

    def build_controller_capture
      controller = Api::BaseController.new
      capture = {}

      controller.define_singleton_method(:render_api_error) do |type:, message:, status:, details: nil|
        capture[:type] = type
        capture[:message] = message
        capture[:status] = status
        capture[:details] = details
      end

      [ controller, capture ]
    end
  end
end
