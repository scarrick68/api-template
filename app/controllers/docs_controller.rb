class DocsController < ApplicationController
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
end
