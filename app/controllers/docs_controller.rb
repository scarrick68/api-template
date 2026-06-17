class DocsController < ApplicationController
  before_action :ensure_docs_available!

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

  def ensure_docs_available!
    return if Rails.env.development?
    return if user_signed_in? && current_user.admin?

    head :not_found
  end
end
