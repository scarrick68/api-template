module Auth
  # DTA session controller for token login/logout endpoints.
  class SessionsController < DeviseTokenAuth::SessionsController
    include Auth::NullSessionForgery

    private

    def append_info_to_payload(payload)
      super

      payload[:user_id] = current_user&.id if respond_to?(:current_user, true)
    end
  end
end
