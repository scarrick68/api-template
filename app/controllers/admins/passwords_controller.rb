module Admins
  # Devise admin passwords controller for cookie-session credential recovery.
  class PasswordsController < Devise::PasswordsController
    private

    def append_info_to_payload(payload)
      super

      payload[:admin_id] = current_admin&.id if respond_to?(:current_admin, true)
    end
  end
end
