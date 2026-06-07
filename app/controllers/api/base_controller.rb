module Api
  class BaseController < ApplicationController
    private

    def api_request_context
      {
        request_id: request.request_id
      }
    end
  end
end
