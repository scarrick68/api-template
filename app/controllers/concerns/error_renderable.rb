module ErrorRenderable
  extend ActiveSupport::Concern

  private

  def render_api_error(type:, message:, status:, details: nil)
    errors = [ message ]
    errors.concat(Array(details)) if details.present?

    payload = {
      success: false,
      errors: errors,
      error_type: type,
      request_id: request.request_id
    }

    render json: payload, status: status
  end
end
