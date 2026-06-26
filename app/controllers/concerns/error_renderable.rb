module ErrorRenderable
  extend ActiveSupport::Concern

  private

  def render_api_error(type:, message:, status:, details: nil)
    error_details = Array(details).compact
    error_details = [ message ] if error_details.empty?

    payload = {
      success: false,
      error: {
        type: type,
        message: message,
        details: error_details
      },
      request_id: request.request_id
    }

    render json: payload, status: status
  end
end
