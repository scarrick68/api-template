class DocsController < ApplicationController
  before_action :authenticate_user!, unless: Rails.env.development?
  before_action :authorize_docs_access!, unless: Rails.env.development?

  def show
    render layout: false
  end

  def openapi
    send_file(
      Rails.root.join("docs", "openapi.yml"),
      type: "application/yaml; charset=utf-8",
      disposition: "inline"
    )
  end

  private

  def authorize_docs_access!
    return if current_user&.admin?

    render_api_error(
      type: "forbidden",
      message: "You are not authorized to perform this action",
      status: :forbidden
    )
  end
end
