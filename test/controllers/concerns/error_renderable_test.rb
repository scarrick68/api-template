require "test_helper"
require "ostruct"

class ErrorRenderableTest < ActiveSupport::TestCase
  class DummyErrorController
    include ErrorRenderable

    attr_reader :render_payload, :render_status

    def initialize(request_id:)
      @request = OpenStruct.new(request_id: request_id)
    end

    def request
      @request
    end

    def render(json:, status:)
      @render_payload = json
      @render_status = status
    end
  end

  test "render_api_error builds standard error envelope" do
    controller = DummyErrorController.new(request_id: "req-123")

    controller.send(
      :render_api_error,
      type: "bad_request",
      message: "invalid request",
      status: :bad_request,
      details: [ "field is required" ]
    )

    assert_equal :bad_request, controller.render_status
    assert_equal(
      {
        success: false,
        errors: [ "invalid request", "field is required" ],
        error_type: "bad_request",
        request_id: "req-123"
      },
      controller.render_payload
    )
  end

  test "render_api_error defaults details to nil when omitted" do
    controller = DummyErrorController.new(request_id: "req-456")

    controller.send(
      :render_api_error,
      type: "internal_server_error",
      message: "An unexpected error occurred",
      status: :internal_server_error
    )

    assert_equal :internal_server_error, controller.render_status
    assert_equal false, controller.render_payload[:success]
    assert_equal [ "An unexpected error occurred" ], controller.render_payload[:errors]
    assert_equal "internal_server_error", controller.render_payload[:error_type]
    assert_equal "req-456", controller.render_payload[:request_id]
  end

  test "render_api_error appends details into the errors array" do
    controller = DummyErrorController.new(request_id: "req-789")

    controller.send(
      :render_api_error,
      type: "unprocessable_entity",
      message: "Validation failed",
      status: :unprocessable_entity,
      details: [ "Email can't be blank", "Password can't be blank" ]
    )

    errors = controller.render_payload[:errors]

    assert_equal :unprocessable_entity, controller.render_status
    assert_equal "unprocessable_entity", controller.render_payload[:error_type]
    assert_equal false, controller.render_payload[:success]
    assert_equal "Validation failed", errors.first
    assert_includes errors, "Email can't be blank", "details should be appended into errors"
    assert_includes errors, "Password can't be blank", "details should be appended into errors"
  end
end
