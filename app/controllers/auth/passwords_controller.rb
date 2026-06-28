module Auth
  # DTA password controller for token-based reset and recovery flows.
  class PasswordsController < DeviseTokenAuth::PasswordsController
    include Auth::NullSessionForgery

    private

    def append_info_to_payload(payload)
      super

      payload[:user_id] = current_user&.id if respond_to?(:current_user, true)
    end
  end
end
