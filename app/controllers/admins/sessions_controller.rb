module Admins
  # Devise admin sessions controller for cookie-based operator authentication.
  class SessionsController < Devise::SessionsController
    private

    def append_info_to_payload(payload)
      super

      payload[:admin_id] = current_admin&.id if respond_to?(:current_admin, true)
    end
  end
end
