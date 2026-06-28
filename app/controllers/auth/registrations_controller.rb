module Auth
  # DTA registration controller for token-based account creation flows.
  class RegistrationsController < DeviseTokenAuth::RegistrationsController
    include Auth::NullSessionForgery

    private

    def append_info_to_payload(payload)
      super

      payload[:user_id] = current_user&.id if respond_to?(:current_user, true)
    end
  end
end
