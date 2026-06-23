module Auth
  module NullSessionForgery
    extend ActiveSupport::Concern

    included do
      protect_from_forgery with: :null_session
      respond_to :json
    end
  end
end
