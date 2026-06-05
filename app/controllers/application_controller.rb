class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes
  include DeviseTokenAuth::Concerns::SetUserByToken
  include ErrorRenderable

  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from ActionController::ParameterMissing, with: :render_bad_request
  rescue_from ActionController::BadRequest, with: :render_bad_request
  rescue_from ActiveRecord::RecordInvalid, with: :render_record_invalid
  rescue_from ActiveRecord::RecordNotSaved, with: :render_record_not_saved
  rescue_from StandardError, with: :render_internal_server_error

  private

  def render_not_found(exception)
    render_api_error(
      type: "not_found",
      message: exception.message,
      status: :not_found
    )
  end

  def render_bad_request(exception)
    render_api_error(
      type: "bad_request",
      message: exception.message,
      status: :bad_request
    )
  end

  def render_record_invalid(exception)
    render_api_error(
      type: "unprocessable_entity",
      message: exception.record.errors.full_messages.to_sentence,
      details: exception.record.errors.full_messages,
      status: :unprocessable_entity
    )
  end

  def render_record_not_saved(exception)
    render_api_error(
      type: "unprocessable_entity",
      message: exception.message,
      details: exception.record&.errors&.full_messages,
      status: :unprocessable_entity
    )
  end

  def render_internal_server_error(_exception)
    render_api_error(
      type: "internal_server_error",
      message: "An unexpected error occurred",
      status: :internal_server_error
    )
  end
end
