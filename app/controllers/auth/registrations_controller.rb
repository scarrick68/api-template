module Auth
  # DTA registration controller for token-based account creation flows.
  # Routes like POST /auth and PUT/PATCH /auth are handled by inherited parent actions.
  class RegistrationsController < DeviseTokenAuth::RegistrationsController
    include Auth::NullSessionForgery

    SIGN_UP_ATTRIBUTE_KEYS = %i[
      email
      password
      password_confirmation
    ].freeze

    ACCOUNT_UPDATE_ATTRIBUTE_KEYS = %i[
      email
      password
      password_confirmation
    ].freeze

    private

    def sign_up_params
      params.permit(*SIGN_UP_ATTRIBUTE_KEYS)
    end

    def account_update_params
      params.permit(*ACCOUNT_UPDATE_ATTRIBUTE_KEYS, :current_password)
    end

    def append_info_to_payload(payload)
      super

      payload[:user_id] = current_user&.id if respond_to?(:current_user, true)
    end
  end
end
